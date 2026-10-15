import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/day_agenda.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation_filter.dart';

import '../reservation_fixtures.dart';

void main() {
  final agenda = DayAgenda(day: day, now: now, reservations: designScenario);

  test('excluye canceladas y ordena por hora de inicio', () {
    expect(agenda.reservations.map((r) => r.id), [
      'done',
      'noshow',
      'live',
      'next-paid',
      'next-due',
    ]);
  });

  test('timingAt clasifica pasada, en juego y próxima', () {
    final byId = {for (final r in agenda.reservations) r.id: r};
    expect(byId['done']!.timingAt(now), ReservationTiming.past);
    expect(byId['live']!.timingAt(now), ReservationTiming.live);
    expect(byId['next-paid']!.timingAt(now), ReservationTiming.upcoming);
    // El final es exclusivo: a la hora exacta de fin ya es pasada.
    expect(byId['live']!.timingAt(byId['live']!.end), ReservationTiming.past);
  });

  test('conteos por filtro', () {
    expect(agenda.countFor(ReservationFilter.live), 1);
    expect(agenda.countFor(ReservationFilter.upcoming), 2);
    expect(agenda.countFor(ReservationFilter.finished), 1);
    expect(agenda.countFor(ReservationFilter.noShow), 1);
  });

  test('indicadores: cobrado y por cobrar (sin no-shows)', () {
    expect(agenda.totalCount, 5);
    expect(agenda.collected, 90000 + 30000 + 40000 + 100000 + 50000);
    // Saldos: en juego 60.000 + próxima 110.000 (no se cuenta el no-show).
    expect(agenda.pending, 60000 + 110000);
    expect(agenda.collectedRatio + agenda.pendingRatio, closeTo(1, 1e-9));
    expect(agenda.finishedRatio, closeTo(2 / 5, 1e-9));
  });

  test('isToday compara solo la fecha', () {
    expect(agenda.isToday, isTrue);
    expect(
      DayAgenda(
        day: day.add(const Duration(days: 1)),
        now: now,
        reservations: const [],
      ).isToday,
      isFalse,
    );
  });

  test('día vacío no divide por cero', () {
    final empty = DayAgenda(day: day, now: now, reservations: const []);
    expect(empty.finishedRatio, 0);
    expect(empty.collectedRatio, 0);
    expect(empty.pendingRatio, 0);
  });
}
