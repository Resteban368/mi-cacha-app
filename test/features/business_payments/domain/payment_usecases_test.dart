import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_payments/domain/entities/new_payment.dart';
import 'package:mi_cancha/features/business_payments/domain/entities/payment.dart';
import 'package:mi_cancha/features/business_payments/domain/repositories/payments_repository.dart';
import 'package:mi_cancha/features/business_payments/domain/usecases/create_payment.dart';
import 'package:mi_cancha/features/business_payments/domain/usecases/validate_payment.dart';
import 'package:mocktail/mocktail.dart';

import '../payment_fixtures.dart';

class _MockRepo extends Mock implements PaymentsRepository {}

void main() {
  late _MockRepo repo;

  setUpAll(
    () => registerFallbackValue(
      const NewPayment(
        customerName: '',
        amount: 0,
        method: PaymentMethod.efectivo,
        concept: PaymentConcept.total,
      ),
    ),
  );
  setUp(() => repo = _MockRepo());

  group('CreatePayment', () {
    NewPayment draft({
      String name = 'Laura',
      int amount = 50000,
      PaymentMethod method = PaymentMethod.nequi,
      String? reference = 'M123',
    }) => NewPayment(
      customerName: name,
      amount: amount,
      method: method,
      concept: PaymentConcept.anticipo,
      reference: reference,
    );

    test('rechaza datos inválidos sin llamar al repositorio', () {
      final useCase = CreatePayment(repo);
      expect(() => useCase(draft(name: '  ')), throwsArgumentError);
      expect(() => useCase(draft(amount: 0)), throwsArgumentError);
      verifyNever(() => repo.create(any()));
    });

    test('la referencia es opcional aunque el método la pida', () async {
      when(() => repo.create(any())).thenAnswer((_) async => payment(id: 'x'));
      await CreatePayment(repo)(draft(reference: ' '));
      verify(() => repo.create(any())).called(1);
    });

    test('efectivo no requiere referencia', () async {
      when(() => repo.create(any())).thenAnswer((_) async => payment(id: 'x'));
      await CreatePayment(repo)(
        draft(method: PaymentMethod.efectivo, reference: null),
      );
      verify(() => repo.create(any())).called(1);
    });
  });

  group('ValidatePayment', () {
    test('aprobar llama a approve', () async {
      when(() => repo.approve('a')).thenAnswer((_) async => payment(id: 'a'));
      await ValidatePayment(repo)(const ValidatePaymentParams.approve('a'));
      verify(() => repo.approve('a')).called(1);
    });

    test('rechazar normaliza un motivo vacío a null', () async {
      when(
        () => repo.reject(any(), reason: any(named: 'reason')),
      ).thenAnswer((_) async => payment(id: 'a'));
      await ValidatePayment(repo)(
        const ValidatePaymentParams.reject('a', reason: '   '),
      );
      verify(() => repo.reject('a', reason: null)).called(1);
    });
  });
}
