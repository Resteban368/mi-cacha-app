import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_reservations/data/datasources/reservations_api_data_source.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';

import '../../../helpers/api_dio.dart';
import '../../../helpers/fake_http_adapter.dart';

void main() {
  Map<String, Object?> reservation(String id, String start, String status) => {
    'id': id,
    'courtId': 'c1',
    'courtName': 'Cancha 1',
    'sport': 'PADEL',
    'start': start,
    'end': '2026-10-14T23:00:00.000Z',
    'customerName': 'Valentina Dussán',
    'customerDetail': null,
    'phone': '3001234567',
    'contactNote': null,
    'tag': 'Torneo',
    'isRecurring': true,
    'totalPrice': 90000,
    'amountPaid': 45000,
    'status': status,
  };

  test('pide el día con formato YYYY-MM-DD y ordena por hora', () async {
    final adapter = FakeHttpAdapter(
      (_) => (
        200,
        [
          reservation('r2', '2026-10-14T22:00:00.000Z', 'NO_SHOW'),
          reservation('r1', '2026-10-14T20:00:00.000Z', 'CONFIRMED'),
        ],
      ),
    );
    final source = ReservationsApiDataSource(apiDio(adapter));

    final list = await source.getReservationsForDay(DateTime(2026, 10, 4));

    final request = adapter.requests.single;
    expect(request.path, '/business/reservations');
    expect(request.queryParameters, {'date': '2026-10-04'});
    expect(list.map((r) => r.id), ['r1', 'r2']);

    final first = list.first;
    expect(first.sport, Sport.padel);
    expect(first.start, DateTime.utc(2026, 10, 14, 20).toLocal());
    expect(first.start.isUtc, isFalse);
    expect(first.balance, 45000);
    expect(first.tag, 'Torneo');
    expect(first.isRecurring, isTrue);
    expect(list.last.status, ReservationStatus.noShow);
  });
}
