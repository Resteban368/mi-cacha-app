import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_sales/data/datasources/cash_api_data_source.dart';

import '../../../helpers/api_dio.dart';
import '../../../helpers/fake_http_adapter.dart';

Object? _body(Object? data) => data is String ? jsonDecode(data) : data;

Map<String, Object?> _session({bool closed = false}) => {
  'id': 'cs-1',
  'openingCash': 50000,
  'openingNote': null,
  'openedAt': '2026-10-28T13:00:00.000Z',
  'openedByName': 'Esteban',
  'closedAt': closed ? '2026-10-29T03:00:00.000Z' : null,
  'closedByName': closed ? 'Esteban' : null,
  'closingNote': null,
  'expectedCash': 55000,
  'countedCash': closed ? 59000 : null,
  'difference': closed ? 4000 : null,
  'methods': [
    {'code': 'EFECTIVO', 'name': 'Efectivo', 'count': 1, 'amount': 5000},
  ],
  'collected': 5000,
};

void main() {
  late FakeHttpAdapter adapter;
  late CashApiDataSource source;

  setUp(() {
    adapter = FakeHttpAdapter((_) => (200, _session()));
    source = CashApiDataSource(apiDio(adapter));
  });

  test('caja actual: abierta y último cierre', () async {
    adapter.handler = (_) =>
        (200, {'session': _session(), 'lastClosed': _session(closed: true)});
    final status = await source.current();
    expect(status.session!.isOpen, isTrue);
    expect(status.session!.expectedCash, 55000);
    expect(status.session!.methods.single.amount, 5000);
    expect(status.lastClosed!.difference, 4000);
  });

  test('sin caja abierta', () async {
    adapter.handler = (_) => (200, {'session': null, 'lastClosed': null});
    final status = await source.current();
    expect(status.session, isNull);
    expect(status.lastClosed, isNull);
  });

  test('abrir y cerrar envían el monto y la nota', () async {
    await source.open(openingCash: 50000, note: ' Tarde ');
    expect(_body(adapter.requests.last.data), {
      'openingCash': 50000,
      'note': 'Tarde',
    });
    expect(adapter.requests.last.path, endsWith('/business/cash/open'));

    adapter.handler = (_) => (200, _session(closed: true));
    final closed = await source.close(countedCash: 59000);
    expect(_body(adapter.requests.last.data), {'countedCash': 59000});
    expect(closed.isOpen, isFalse);
  });
}
