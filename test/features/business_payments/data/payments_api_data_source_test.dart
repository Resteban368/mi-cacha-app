import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_payments/data/datasources/payments_api_data_source.dart';
import 'package:mi_cancha/features/business_payments/domain/entities/new_payment.dart';
import 'package:mi_cancha/features/business_payments/domain/entities/payment.dart';

import '../../../helpers/api_dio.dart';
import '../../../helpers/fake_http_adapter.dart';

Object? _body(Object? data) => data is String ? jsonDecode(data) : data;

void main() {
  Map<String, Object?> payment({
    String id = 'p1',
    String method = 'NEQUI',
    String status = 'PENDING',
    String receivedAt = '2026-10-14T15:00:00.000Z',
  }) => {
    'id': id,
    'customerName': 'Camilo Méndez',
    'amount': 60000,
    'method': method,
    'concept': 'ANTICIPO',
    'receivedAt': receivedAt,
    'status': status,
    'reservationId': null,
    'courtName': 'Cancha 2',
    'reservationStart': '2026-10-14T23:00:00.000Z',
    'reference': 'M4829310',
    'note': null,
    'rejectionReason': null,
    'registeredByBusiness': false,
  };

  late FakeHttpAdapter adapter;
  late PaymentsApiDataSource source;

  setUp(() {
    adapter = FakeHttpAdapter((_) => (200, payment()));
    source = PaymentsApiDataSource(apiDio(adapter));
  });

  test('lista los pagos del más reciente al más antiguo', () async {
    adapter.handler = (_) => (
      200,
      [
        payment(id: 'viejo', receivedAt: '2026-10-13T10:00:00.000Z'),
        payment(id: 'nuevo', method: 'BRE_B', status: 'APPROVED'),
        payment(id: 'raro', method: 'CRIPTO', status: 'REJECTED'),
      ],
    );

    final list = await source.getPayments();

    expect(list.map((p) => p.id), ['nuevo', 'raro', 'viejo']);
    final nuevo = list.first;
    expect(nuevo.method, PaymentMethod.breB);
    expect(nuevo.status, PaymentStatus.approved);
    expect(nuevo.concept, PaymentConcept.anticipo);
    expect(nuevo.reservationStart, DateTime.utc(2026, 10, 14, 23).toLocal());
    expect(list[1].method, PaymentMethod.otro);
    expect(list[1].status, PaymentStatus.rejected);
  });

  test('aprobar usa PATCH /:id/approve', () async {
    adapter.handler = (_) => (200, payment(status: 'APPROVED'));

    final updated = await source.updateStatus('p1', PaymentStatus.approved);

    final request = adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.path, '/business/payments/p1/approve');
    expect(updated.status, PaymentStatus.approved);
  });

  test('rechazar envía el motivo', () async {
    adapter.handler = (_) => (200, payment(status: 'REJECTED'));

    await source.updateStatus(
      'p1',
      PaymentStatus.rejected,
      rejectionReason: 'No coincide el valor',
    );

    final request = adapter.requests.single;
    expect(request.path, '/business/payments/p1/reject');
    expect(_body(request.data), {'reason': 'No coincide el valor'});
  });

  test('volver a pendiente no se permite', () {
    expect(
      () => source.updateStatus('p1', PaymentStatus.pending),
      throwsArgumentError,
    );
  });

  test('crear envía códigos de la API y omite campos vacíos', () async {
    await source.create(
      const NewPayment(
        customerName: ' Camilo ',
        amount: 60000,
        method: PaymentMethod.bancolombiaQr,
        concept: PaymentConcept.saldo,
        reference: ' QR-77 ',
        note: '',
      ),
    );

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/business/payments');
    expect(_body(request.data), {
      'customerName': 'Camilo',
      'amount': 60000,
      'method': 'BANCOLOMBIA_QR',
      'concept': 'SALDO',
      'reference': 'QR-77',
    });
  });

  test('"Otro medio" no se ofrece al registrar un pago', () {
    expect(PaymentMethod.selectable, isNot(contains(PaymentMethod.otro)));
    expect(PaymentMethod.selectable, contains(PaymentMethod.breB));
  });
}
