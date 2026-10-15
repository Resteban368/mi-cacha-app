import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/utils/clock.dart';
import 'package:mi_cancha/features/business_payments/data/datasources/payments_data_source.dart';
import 'package:mi_cancha/features/business_payments/domain/entities/new_payment.dart';
import 'package:mi_cancha/features/business_payments/domain/entities/payment.dart';

void main() {
  late FakePaymentsDataSource source;

  setUp(
    () =>
        source = FakePaymentsDataSource(const Clock(), latency: Duration.zero),
  );

  test(
    'incluye pendientes, aprobados y rechazados, más recientes primero',
    () async {
      final list = await source.getPayments();
      expect(list.where((p) => p.status == PaymentStatus.pending), isNotEmpty);
      expect(list.where((p) => p.status == PaymentStatus.approved), isNotEmpty);
      expect(list.where((p) => p.status == PaymentStatus.rejected), isNotEmpty);
      for (var i = 1; i < list.length; i++) {
        expect(list[i - 1].receivedAt.isAfter(list[i].receivedAt), isTrue);
      }
    },
  );

  test('los cambios de estado persisten durante la sesión', () async {
    await source.updateStatus(
      'p1',
      PaymentStatus.rejected,
      rejectionReason: 'Duplicado',
    );
    final p1 = (await source.getPayments()).firstWhere((p) => p.id == 'p1');
    expect(p1.status, PaymentStatus.rejected);
    expect(p1.rejectionReason, 'Duplicado');
  });

  test('crear registra un pago aprobado hecho por el negocio', () async {
    final created = await source.create(
      const NewPayment(
        customerName: '  Laura  ',
        amount: 45000,
        method: PaymentMethod.efectivo,
        concept: PaymentConcept.total,
      ),
    );
    expect(created.status, PaymentStatus.approved);
    expect(created.registeredByBusiness, isTrue);
    expect(created.customerName, 'Laura');
    expect(await source.getPayments(), contains(created));
  });

  test('actualizar un pago inexistente falla', () {
    expect(
      () => source.updateStatus('nope', PaymentStatus.approved),
      throwsStateError,
    );
  });
}
