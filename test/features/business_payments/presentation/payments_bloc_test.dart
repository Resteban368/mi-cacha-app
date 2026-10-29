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
    expect(state.visible.map((p) => p.id), ['c']);
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

  test('filtros: cancha, medio de pago y rango de fechas', () {
    final state = PaymentsState(
      status: PaymentsStatus.success,
      payments: [
        payment(id: 'x', status: PaymentStatus.approved),
        payment(
          id: 'y',
          status: PaymentStatus.approved,
          method: PaymentMethod.efectivo,
          minutesAgo: 60 * 24 * 3,
        ),
      ],
    );
    expect(state.visible, hasLength(2));
    expect(state.courtOptions, ['Cancha Múltiple']);
    expect(state.methodOptions, [PaymentMethod.efectivo, PaymentMethod.nequi]);

    ids(PaymentsFilter f) =>
        state.copyWith(filter: f).visible.map((p) => p.id).toList();
    expect(ids(const PaymentsFilter(method: PaymentMethod.efectivo)), ['y']);
    expect(ids(const PaymentsFilter(court: 'Otra')), isEmpty);
    expect(ids(PaymentsFilter(from: now, to: now)), ['x']);
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    expect(ids(PaymentsFilter(from: threeDaysAgo, to: now)), ['x', 'y']);
    expect(ids(PaymentsFilter(to: threeDaysAgo)), ['y']);
    expect(ids(PaymentsFilter(from: now.subtract(const Duration(days: 2)))), [
      'x',
    ]);
  });

  test('resumen: total, por medio de pago y por concepto', () {
    final state = PaymentsState(
      status: PaymentsStatus.success,
      payments: [
        // Reserva: cancha 60.000 + consumos 50.000 pagados juntos.
        payment(
          id: 'r',
          status: PaymentStatus.approved,
          amount: 110000,
          productsAmount: 50000,
        ),
        payment(
          id: 'v',
          status: PaymentStatus.approved,
          amount: 10000,
          method: PaymentMethod.efectivo,
          walkIn: true,
        ),
        payment(
          id: 'c',
          status: PaymentStatus.approved,
          amount: 40000,
          method: PaymentMethod.efectivo,
        ),
        payment(id: 'p', amount: 99999),
      ],
    );
    final s = state.summary;
    expect(s.count, 3);
    expect(s.total, 160000);
    expect(s.courts, 100000);
    expect(s.consumptions, 50000);
    expect(s.walkIn, 10000);
    expect(s.byMethod.map((e) => (e.key, e.value)), [
      (PaymentMethod.nequi, 110000),
      (PaymentMethod.efectivo, 50000),
    ]);
    // Sigue el filtro.
    final cash = state.copyWith(
      filter: const PaymentsFilter(method: PaymentMethod.efectivo),
    );
    expect(cash.summary.total, 50000);
    expect(cash.summary.consumptions, 0);
  });

  blocTest<PaymentsBloc, PaymentsState>(
    'cambia el filtro',
    build: build,
    seed: loaded,
    act: (bloc) => bloc.add(
      const PaymentsFilterChanged(PaymentsFilter(court: 'Cancha Múltiple')),
    ),
    expect: () => [
      isA<PaymentsState>().having(
        (s) => s.filter.court,
        'cancha',
        'Cancha Múltiple',
      ),
    ],
  );
}
