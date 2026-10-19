import 'package:equatable/equatable.dart';

import '../../../business_courts/domain/entities/court.dart';
import '../../../business_courts/domain/entities/court_schedule.dart';
import '../../../business_courts/domain/entities/week_day.dart';
import 'day_agenda.dart';
import 'reservation.dart';

/// Ocupación de una cancha en el día: horas reservadas sobre horas abiertas
/// según su horario de esa fecha. Las canceladas no cuentan, y solo cuenta
/// lo reservado dentro del horario abierto.
class CourtOccupancy extends Equatable {
  const CourtOccupancy({
    required this.courtId,
    required this.name,
    required this.bookedMinutes,
    required this.openMinutes,
  });

  final String courtId;
  final String name;
  final int bookedMinutes;

  /// 0 si la cancha no abre ese día.
  final int openMinutes;

  bool get isClosed => openMinutes == 0;

  /// Proporción ocupada (0–1).
  double get fraction =>
      isClosed ? 0 : (bookedMinutes / openMinutes).clamp(0.0, 1.0).toDouble();

  /// Ocupación de cada cancha activa con las reservas activas del día.
  static List<CourtOccupancy> forDay(List<Court> courts, DayAgenda agenda) {
    final weekDay = WeekDay.values[agenda.day.weekday - 1];
    return [
      for (final court in courts)
        if (court.isActive) _forCourt(court, weekDay, agenda),
    ];
  }

  static CourtOccupancy _forCourt(
    Court court,
    WeekDay weekDay,
    DayAgenda agenda,
  ) {
    final schedule = court.schedules.where((s) => s.day == weekDay).firstOrNull;
    final isOpen = schedule != null && schedule.isOpen;
    final openMinutes = isOpen ? _openMinutes(schedule) : 0;
    if (!isOpen) {
      return CourtOccupancy(
        courtId: court.id,
        name: court.name,
        bookedMinutes: 0,
        openMinutes: 0,
      );
    }
    final windowStart = DateTime(
      agenda.day.year,
      agenda.day.month,
      agenda.day.day,
      schedule.open!.hour,
      schedule.open!.minute,
    );
    final windowEnd = windowStart.add(Duration(minutes: openMinutes));

    var booked = 0;
    for (final r in agenda.reservations) {
      if (!_isOn(court, r)) continue;
      final from = r.start.isAfter(windowStart) ? r.start : windowStart;
      final to = r.end.isBefore(windowEnd) ? r.end : windowEnd;
      if (to.isAfter(from)) booked += to.difference(from).inMinutes;
    }
    return CourtOccupancy(
      courtId: court.id,
      name: court.name,
      bookedMinutes: booked,
      openMinutes: openMinutes,
    );
  }

  static bool _isOn(Court court, Reservation r) {
    final group = r.group;
    if (group != null) return group.courts.any((c) => c.courtId == court.id);
    return r.courtId != null
        ? r.courtId == court.id
        : r.courtName == court.name;
  }

  static int _openMinutes(DaySchedule schedule) {
    final open = schedule.open!.inMinutes;
    final close = schedule.close!.inMinutes;
    return schedule.closesNextDay ? close + 24 * 60 - open : close - open;
  }

  @override
  List<Object?> get props => [courtId, name, bookedMinutes, openMinutes];
}
