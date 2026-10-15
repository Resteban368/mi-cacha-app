import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/utils/clock.dart';
import 'package:mi_cancha/features/business_reservations/data/datasources/reservations_data_source.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/day_agenda.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation_filter.dart';

class _FixedClock extends Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

void main() {
  test('hoy siempre incluye pasadas, una en juego y próximas', () async {
    for (final hour in [8, 13, 19, 22]) {
      final now = DateTime(2026, 10, 9, hour, 7);
      final source = FakeReservationsDataSource(
        _FixedClock(now),
        latency: Duration.zero,
      );
      final list = await source.getReservationsForDay(DateTime(2026, 10, 9));
      final agenda = DayAgenda(
        day: DateTime(2026, 10, 9),
        now: now,
        reservations: list,
      );
      expect(agenda.countFor(ReservationFilter.live), 1, reason: '$hour h');
      expect(agenda.countFor(ReservationFilter.upcoming), 2);
      expect(agenda.countFor(ReservationFilter.finished), 1);
      expect(agenda.countFor(ReservationFilter.noShow), 1);
    }
  });
}
