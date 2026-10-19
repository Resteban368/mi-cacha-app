import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court_schedule.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court_time.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/week_day.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/court_occupancy.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/day_agenda.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';

import '../reservation_fixtures.dart';

Court _court(String name, {List<DaySchedule>? schedules, bool active = true}) =>
    Court(
      id: name,
      name: name,
      sport: Sport.futbol,
      isActive: active,
      isComplete: true,
      isBookable: true,
      schedules: schedules ?? DaySchedule.defaultWeek(),
    );

void main() {
  // `day` del fixture es viernes, 9 de octubre de 2026.
  test('horas reservadas sobre horas abiertas del día', () {
    final agenda = DayAgenda(
      day: day,
      now: now,
      reservations: [
        reservation(id: 'c1', startHour: 16, minutes: 90),
        // Cancelada: no cuenta.
        reservation(
          id: 'c1',
          startHour: 18,
          minutes: 60,
          status: ReservationStatus.cancelled,
        ),
      ],
    );
    final o = CourtOccupancy.forDay([_court('Cancha c1')], agenda).single;
    // Viernes 06:00 a 22:00 = 960 min; reservado 90 min.
    expect(o.openMinutes, 960);
    expect(o.bookedMinutes, 90);
    expect(o.fraction, closeTo(90 / 960, 1e-9));
  });

  test('cancha cerrada ese día: 0% y marcada como cerrada', () {
    final schedules = [
      for (final d in DaySchedule.defaultWeek())
        d.day == WeekDay.friday ? DaySchedule.closed(WeekDay.friday) : d,
    ];
    final agenda = DayAgenda(day: day, now: now, reservations: const []);
    final o = CourtOccupancy.forDay([
      _court('Cancha cerrada', schedules: schedules),
    ], agenda).single;
    expect(o.isClosed, isTrue);
    expect(o.fraction, 0);
  });

  test('canchas inactivas no aparecen', () {
    final agenda = DayAgenda(day: day, now: now, reservations: const []);
    expect(
      CourtOccupancy.forDay([_court('Inactiva', active: false)], agenda),
      isEmpty,
    );
  });

  test('solo cuenta lo reservado dentro del horario abierto', () {
    final agenda = DayAgenda(
      day: day,
      now: now,
      // 21:00 a 01:00, pero la cancha cierra a las 22:00: 60 min cuentan.
      reservations: [reservation(id: 'c1', startHour: 21, minutes: 240)],
    );
    final o = CourtOccupancy.forDay([_court('Cancha c1')], agenda).single;
    expect(o.bookedMinutes, 60);
    expect(o.fraction, closeTo(60 / 960, 1e-9));
  });

  test('horario que cierra al día siguiente suma las horas de madrugada', () {
    final schedules = [
      for (final d in DaySchedule.defaultWeek())
        d.day == WeekDay.friday
            ? DaySchedule.open(
                WeekDay.friday,
                open: const CourtTime(18),
                close: const CourtTime(2),
              )
            : d,
    ];
    final agenda = DayAgenda(day: day, now: now, reservations: const []);
    final o = CourtOccupancy.forDay([
      _court('Nocturna', schedules: schedules),
    ], agenda).single;
    expect(o.openMinutes, 8 * 60);
  });
}
