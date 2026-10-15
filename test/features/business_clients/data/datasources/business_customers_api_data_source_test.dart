import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_clients/data/datasources/business_customers_api_data_source.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/client_filter.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_failure.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_payload.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_query.dart';

import '../../../../helpers/api_dio.dart';
import '../../../../helpers/fake_http_adapter.dart';

void main() {
  final sampleCustomerJson = {
    'id': 'cust-1',
    'name': 'Carlos Mendoza',
    'phone': '+573114567890',
    'documentId': '1020334881',
    'preferredSport': 'FUTBOL',
    'notes': 'Capitán de equipo',
    'createdAt': '2026-10-13T10:00:00Z',
    'metrics': {
      'reservations': 24,
      'level': 'VIP',
      'attendancePct': 92,
      'totalSpent': 1920000,
      'balance': 0,
      'favoriteSport': 'FUTBOL',
      'lastVisit': {
        'date': '2026-10-13T18:00:00Z',
        'courtName': 'Cancha Sintética 1',
      },
    },
  };

  final samplePageJson = {
    'overview': {
      'totalCustomers': 6,
      'newThisMonth': 2,
      'newVsLastMonthPct': 14,
      'loyalCustomers': 3,
      'loyalPct': 50,
      'totalReservations': 54,
      'pendingBalance': 115000,
      'currency': 'COP',
    },
    'items': [sampleCustomerJson],
    'total': 1,
    'page': 1,
    'pageSize': 20,
  };

  late FakeHttpAdapter adapter;
  late BusinessCustomersApiDataSource dataSource;

  setUp(() {
    adapter = FakeHttpAdapter((_) => (200, samplePageJson));
    dataSource = BusinessCustomersApiDataSource(apiDio(adapter));
  });

  Map<String, dynamic> body(RequestOptions req) =>
      (req.data is String ? jsonDecode(req.data as String) : req.data)
          as Map<String, dynamic>;

  group('getCustomers', () {
    test('envía query parameters correctos y mapea la respuesta', () async {
      final res = await dataSource.getCustomers(
        const CustomerQuery(
          page: 2,
          pageSize: 10,
          search: 'Carlos',
          segment: ClientFilterSegment.loyal,
          sort: ClientFilterSort.mostReservations,
        ),
      );

      final req = adapter.requests.single;
      expect(req.path, '/business/customers');
      expect(req.queryParameters['page'], 2);
      expect(req.queryParameters['pageSize'], 10);
      expect(req.queryParameters['search'], 'Carlos');
      expect(req.queryParameters['segment'], 'LOYAL');
      expect(req.queryParameters['sort'], 'MOST_RESERVATIONS');

      expect(res.total, 1);
      expect(res.page, 1);
      expect(res.pageSize, 20);
      expect(res.overview.totalCustomers, 6);
      expect(res.overview.pendingBalance, 115000);
      expect(res.items.length, 1);
      expect(res.items.first.name, 'Carlos Mendoza');
      expect(res.items.first.preferredSport, Sport.futbol);
      expect(res.items.first.metrics?.reservations, 24);
    });

    test('mapea error genérico en falla 500', () async {
      adapter = FakeHttpAdapter((_) => (500, {'message': 'Server error'}));
      dataSource = BusinessCustomersApiDataSource(apiDio(adapter));

      expect(
        () => dataSource.getCustomers(const CustomerQuery()),
        throwsA(isA<CustomerFailure>()),
      );
    });
  });

  group('createCustomer', () {
    test('envía payload y retorna el cliente creado', () async {
      adapter = FakeHttpAdapter((_) => (201, sampleCustomerJson));
      dataSource = BusinessCustomersApiDataSource(apiDio(adapter));

      final created = await dataSource.createCustomer(
        const CustomerPayload(
          name: 'Carlos Mendoza',
          phone: '+573114567890',
          documentId: '1020334881',
          preferredSport: Sport.futbol,
          notes: 'Capitán de equipo',
        ),
      );

      final req = adapter.requests.single;
      expect(req.method, 'POST');
      expect(req.path, '/business/customers');
      final reqBody = body(req);
      expect(reqBody['name'], 'Carlos Mendoza');
      expect(reqBody['phone'], '+573114567890');
      expect(reqBody['documentId'], '1020334881');
      expect(reqBody['preferredSport'], 'FUTBOL');
      expect(reqBody['notes'], 'Capitán de equipo');

      expect(created.name, 'Carlos Mendoza');
      expect(created.id, 'cust-1');
    });

    test('mapea 409 Conflict a CustomerFailure.conflict', () async {
      adapter = FakeHttpAdapter((_) => (409, {
            'error': 'CONFLICT',
            'message': 'Ya existe un cliente con este teléfono',
          }));
      dataSource = BusinessCustomersApiDataSource(apiDio(adapter));

      expect(
        () => dataSource.createCustomer(
          const CustomerPayload(
            name: 'Carlos Mendoza',
            phone: '+573114567890',
          ),
        ),
        throwsA(
          isA<CustomerFailure>().having(
            (e) => e.isConflict,
            'isConflict',
            isTrue,
          ),
        ),
      );
    });
  });

  group('updateCustomer', () {
    test('envía PATCH al path correcto con datos parciales', () async {
      adapter = FakeHttpAdapter((_) => (200, sampleCustomerJson));
      dataSource = BusinessCustomersApiDataSource(apiDio(adapter));

      final updated = await dataSource.updateCustomer(
        'cust-1',
        const CustomerPayload(
          name: 'Carlos Editado',
          notes: 'Nueva nota',
        ),
      );

      final req = adapter.requests.single;
      expect(req.method, 'PATCH');
      expect(req.path, '/business/customers/cust-1');
      final reqBody = body(req);
      expect(reqBody['name'], 'Carlos Editado');
      expect(reqBody['notes'], 'Nueva nota');
      expect(updated.id, 'cust-1');
    });
  });
}
