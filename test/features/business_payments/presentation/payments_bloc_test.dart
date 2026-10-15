import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/business_payments/domain/entities/payment.dart';
import 'package:mi_cancha/features/business_payments/domain/usecases/get_payments.dart';
import 'package:mi_cancha/features/business_payments/domain/usecases/validate_payment.dart';
import 'package:mi_cancha/features/business_payments/presentation/bloc/payments/payments_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../payment_fixtures.dart';

class _MockGet extends Mock implements GetPayments {}

class _MockValidate extends Mock implements ValidatePayment {}

void main() {
  late _MockGet getPayments;
  late _MockValidate validate;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const ValidatePaymentParams.approve(''));
  });

  setUp(() {
    getPayments = _MockGet();
    validate = _MockValidate();
    when(() => getPayments(any())).thenAnswer((_) async => samplePayments);
  });

  PaymentsBloc build() =>
      PaymentsBloc(getPayments: getPayments, validatePayment: validate);

  PaymentsState loaded() =>
      PaymentsState(status: PaymentsStatus.success, payments: samplePayments);

  test('getters: conteos, visibles y monto pendiente', () {
    final state = loaded();
    expect(state.countFor(PaymentStatus.pending), 2);
    expect(state.visible.map((p) => p.id), ['a', 'b']);
    expect(state.pendingAmount, 110000);
  });

  blocTest<PaymentsBloc, PaymentsState>(
    'carga los pagos',
    build: build,
    act: (bloc) => bloc.add(const PaymentsRequested()),
    expect: () => [
      const PaymentsState(status: PaymentsStatus.loading),
      loaded(),
    ],
  );

  blocTest<PaymentsBloc, PaymentsState>(
    'aprobar marca "procesando", actualiza el pago y avisa',
    setUp: () => when(
      () => validate(any()),
    ).thenAnswer((_) async => payment(id: 'a', status: PaymentStatus.approved)),
    build: build,
    seed: loaded,
    act: (bloc) => bloc.add(const PaymentApproved('a')),
    expect: () => [
      isA<PaymentsState>().having((s) => s.processing, 'processing', {'a'}),
      isA<PaymentsState>()
          .having((s) => s.processing, 'processing', isEmpty)
          .having((s) => s.countFor(PaymentStatus.pending), 'pendientes', 1)
          .having(
            (s) => s.notice?.message,
            'aviso',
            r'Pago de $60.000 aprobado',
          )
          .having((s) => s.notice?.isError, 'error', false),
    ],
    verify: (_) => verify(
      () => validate(const ValidatePaymentParams.approve('a')),
    ).called(1),
  );

  blocTest<PaymentsBloc, PaymentsState>(
    'rechazar envía el motivo',
    setUp: () => when(
      () => validate(any()),
    ).thenAnswer((_) async => payment(id: 'b', status: PaymentStatus.rejected)),
    build: build,
    seed: loaded,
    act: (bloc) => bloc.add(const PaymentRejected('b', reason: 'Duplicado')),
    skip: 1,
    expect: () => [
      isA<PaymentsState>().having(
        (s) => s.countFor(PaymentStatus.rejected),
        'rechazados',
        2,
      ),
    ],
    verify: (_) => verify(
      () => validate(
        const ValidatePaymentParams.reject('b', reason: 'Duplicado'),
      ),
    ).called(1),
  );

  blocTest<PaymentsBloc, PaymentsState>(
    'si validar falla, conserva el pago pendiente y avisa el error',
    setUp: () => when(() => validate(any())).thenThrow(Exception('x')),
    build: build,
    seed: loaded,
    act: (bloc) => bloc.add(const PaymentApproved('a')),
    skip: 1,
    expect: () => [
      isA<PaymentsState>()
          .having((s) => s.countFor(PaymentStatus.pending), 'pendientes', 2)
          .having((s) => s.processing, 'processing', isEmpty)
          .having((s) => s.notice?.isError, 'error', true),
    ],
  );

  blocTest<PaymentsBloc, PaymentsState>(
    'cambia de pestaña',
    build: build,
    seed: loaded,
    act: (bloc) => bloc.add(const PaymentsTabChanged(PaymentStatus.rejected)),
    expect: () => [
      isA<PaymentsState>().having((s) => s.visible.single.id, 'visible', 'd'),
    ],
  );
}
