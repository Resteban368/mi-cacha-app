import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_payments/domain/entities/payment.dart';
import 'package:mi_cancha/features/business_reservations/data/datasources/reservations_api_data_source.dart';
import 'package:mi_cancha/features/business_reservations/data/repositories/reservations_repository_impl.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/availability.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/customer.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/new_reservation.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation_failure.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation_query.dart';

import '../../../helpers/api_dio.dart';
import '../../../helpers/fake_http_adapter.dart';

void main() {
  // Respuesta 201 del contrato.
  final reservationJson = {
    'id': '8ad4101a',
    'courtId': 'c1',
    'courtName': 'Sintética 1',
    'sport': 'FUTBOL',
    'start': '2026-10-15T22:00:00.000Z',
    'end': '2026-10-16T00:00:00.000Z',
    'customer': {
      'id': 'cu1',
      'name': 'Laura Gómez',
      'phone': '3115550001',
      'documentId': '1075111222',
      'createdAt': '2026-10-14T23:15:00.000Z',
    },
    'customerName': 'Laura Gómez',
    'customerDetail': 'Equipo Los Halcones',
    'phone': '3115550001',
    'contactNote': 'Llega 10 min antes',
    'tag': 'Torneo',
    'isRecurring': false,
    'subtotal': 264000,
    'discount': 14000,
    'totalPrice': 250000,
    'currency': 'COP',
    'amountPaid': 50000,
    'balance': 200000,
    'payments': [
      {
        'id': 'p1',
        'amount': 50000,
        'method': 'NEQUI',
        'concept': 'ANTICIPO',
        'status': 'APPROVED',
        'reference': 'M123456',
        'receivedAt': '2026-10-15T15:00:00.000Z',
      },
    ],
    'status': 'CONFIRMED',
    'cancellationReason': null,
    'cancelledAt': null,
    'cancelledBy': null,
  };

  late FakeHttpAdapter adapter;
  late ReservationsApiDataSource source;

  setUp(() {
    adapter = FakeHttpAdapter((_) => (201, reservationJson));
    source = ReservationsApiDataSource(apiDio(adapter));
  });

  Map<String, dynamic> body(RequestOptions r) =>
      (r.data is String ? jsonDecode(r.data as String) : r.data)
          as Map<String, dynamic>;

  test(
    'disponibilidad: pide la fecha local y conserva el inicio exacto',
    () async {
      adapter.handler = (_) => (
        200,
        {
          'date': '2026-10-15',
          'courtId': 'c1',
          'slotDuration': 60,
          'currency': 'COP',
          'maxSlots': 5,
          'slots': [
            {
              'start': '2026-10-15T23:00:00.000Z',
              'end': '2026-10-16T00:00:00.000Z',
              'status': 'BOOKED',
              'price': 144000,
            },
            {
              'start': '2026-10-15T22:00:00.000Z',
              'end': '2026-10-15T23:00:00.000Z',
              'status': 'AVAILABLE',
              'price': 120000,
            },
          ],
        },
      );

      final result = await source.getAvailability(
        'c1',
        DateTime(2026, 10, 15, 9),
      );

      final request = adapter.requests.single;
      expect(request.path, '/business/courts/c1/availability');
      expect(request.queryParameters, {'date': '2026-10-15'});
      expect(result.maxSlots, 5);
      // Ordenados por hora.
      expect(result.slots.first.startIso, '2026-10-15T22:00:00.000Z');
      expect(result.slots.first.status, SlotStatus.available);
      expect(result.slots.last.status, SlotStatus.booked);
      expect(result.slots.last.price, 144000);
    },
  );

  test('busca clientes; sin texto no envía search', () async {
    adapter.handler = (_) => (
      200,
      [
        {
          'id': 'cu1',
          'name': 'Laura Gómez',
          'phone': '3115550001',
          'documentId': '1075111222',
          'createdAt': '2026-10-14T23:15:00.000Z',
        },
      ],
    );
    final found = await source.searchCustomers(' laura ');
    await source.searchCustomers('');

    expect(adapter.requests[0].queryParameters, {'search': 'laura'});
    expect(adapter.requests[1].queryParameters, isEmpty);
    expect(found.single.name, 'Laura Gómez');
  });

  test(
    'crea con cliente nuevo, pago y descuento, y lee la respuesta',
    () async {
      final r = await source.create(
        const NewReservation(
          courtId: 'c1',
          start: '2026-10-15T22:00:00.000Z',
          slots: 2,
          customer: NewCustomer(
            name: ' Laura Gómez ',
            phone: '311 555 0001',
            documentId: '1.075.111.222',
          ),
          customerDetail: 'Equipo Los Halcones',
          contactNote: '  ',
          tag: 'Torneo',
          discount: 14000,
          payment: NewPayment(
            amount: 50000,
            method: 'NEQUI',
            reference: 'M123456',
          ),
        ),
      );

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/business/reservations');
      expect(body(request), {
        'courtId': 'c1',
        'start': '2026-10-15T22:00:00.000Z',
        'slots': 2,
        'customer': {
          'name': 'Laura Gómez',
          'phone': '311 555 0001',
          'documentId': '1.075.111.222',
        },
        'customerDetail': 'Equipo Los Halcones',
        'tag': 'Torneo',
        'isRecurring': false,
        'discount': 14000,
        'payment': {'amount': 50000, 'method': 'NEQUI', 'reference': 'M123456'},
      });

      expect(r.subtotal, 264000);
      expect(r.totalPrice, 250000);
      expect(r.balance, 200000);
      expect(r.customer!.documentId, '1075111222');
      expect(r.payments.single.concept, PaymentConcept.anticipo);
      expect(r.payments.single.status, PaymentStatus.approved);
    },
  );

  test('con cliente existente envía solo customerId', () async {
    await source.create(
      const NewReservation(
        courtId: 'c1',
        start: '2026-10-15T22:00:00.000Z',
        slots: 1,
        customerId: 'cu1',
      ),
    );
    final json = body(adapter.requests.single);
    expect(json['customerId'], 'cu1');
    expect(json.containsKey('customer'), isFalse);
    expect(json.containsKey('payment'), isFalse);
    expect(json.containsKey('discount'), isFalse);
  });

  test('cancelar con motivo y cambiar estado', () async {
    adapter.handler = (_) => (
      200,
      {
        ...reservationJson,
        'status': 'CANCELLED',
        'cancellationReason': 'Llueve',
        'cancelledAt': '2026-10-15T16:00:00.000Z',
        'cancelledBy': 'Cliente dev',
      },
    );
    final cancelled = await source.cancel('r1', ' Llueve ');
    await source.updateStatus('r1', ReservationStatus.completed);

    expect(adapter.requests[0].path, '/business/reservations/r1/cancel');
    expect(body(adapter.requests[0]), {'reason': 'Llueve'});
    expect(adapter.requests[1].method, 'PATCH');
    expect(adapter.requests[1].path, '/business/reservations/r1/status');
    expect(body(adapter.requests[1]), {'status': 'COMPLETED'});
    expect(cancelled.status, ReservationStatus.cancelled);
    expect(cancelled.cancelledBy, 'Cliente dev');
  });

  test('listado: sin date, con filtros y paginado', () async {
    adapter.handler = (_) => (
      200,
      {
        'items': [reservationJson],
        'total': 41,
        'page': 2,
        'pageSize': 20,
      },
    );
    final page = await source.listReservations(
      ReservationQuery(
        search: ' 1.075.111 ',
        status: ReservationStatus.confirmed,
        courtId: 'c1',
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 31),
      ),
      page: 2,
      pageSize: 20,
    );

    final request = adapter.requests.single;
    expect(request.path, '/business/reservations');
    expect(request.queryParameters, {
      'page': 2,
      'pageSize': 20,
      'search': '1.075.111',
      'status': 'CONFIRMED',
      'courtId': 'c1',
      'from': '2026-10-01',
      'to': '2026-10-31',
    });
    expect(page.items.single.id, '8ad4101a');
    expect(page.total, 41);
    expect(page.hasMore, isTrue); // 2 × 20 < 41
  });

  test('listado sin filtros solo envía la página', () async {
    adapter.handler = (_) =>
        (200, {'items': <Object>[], 'total': 0, 'page': 1, 'pageSize': 20});
    final page = await source.listReservations(
      const ReservationQuery(),
      page: 1,
      pageSize: 20,
    );
    expect(adapter.requests.single.queryParameters, {
      'page': 1,
      'pageSize': 20,
    });
    expect(page.hasMore, isFalse);
  });

  group('errores', () {
    Future<ReservationException> failWith(int status, Object body) async {
      adapter.handler = (_) => (status, body);
      try {
        await ReservationsRepositoryImpl(source).create(
          const NewReservation(
            courtId: 'c1',
            start: 's',
            slots: 1,
            customerId: 'cu1',
          ),
        );
      } on ReservationException catch (error) {
        return error;
      }
      fail('debía fallar');
    }

    test('409 turno ocupado', () async {
      final e = await failWith(409, {
        'statusCode': 409,
        'message': 'La cancha ya está reservada en ese horario',
      });
      expect(e.failure, ReservationFailure.slotTaken);
    });

    test('409 cancha no reservable', () async {
      final e = await failWith(409, {
        'message': 'La cancha está incompleta: le faltan las fotos LIGHTING',
      });
      expect(e.failure, ReservationFailure.courtNotBookable);
    });

    test('409 teléfono y cédula de clientes distintos', () async {
      final e = await failWith(409, {
        'message':
            'El teléfono es de Ana y la cédula de Luis: revisa los datos del '
            'cliente',
      });
      expect(e.failure, ReservationFailure.customerConflict);
      expect(e.message, startsWith('El teléfono es de Ana'));
    });

    test('403 plan inactivo', () async {
      final e = await failWith(403, {
        'statusCode': 403,
        'code': 'SUBSCRIPTION_INACTIVE',
        'message': 'Tu plan no está activo',
      });
      expect(e.failure, ReservationFailure.subscriptionInactive);
    });

    test('400 con lista de mensajes: uno por línea', () async {
      final e = await failWith(400, {
        'message': ['slots must not be greater than 5', 'start no es válido'],
      });
      expect(e.failure, ReservationFailure.invalid);
      expect(e.message, 'slots must not be greater than 5\nstart no es válido');
    });
  });
}
