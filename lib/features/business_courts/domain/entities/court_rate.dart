import 'package:equatable/equatable.dart';

import 'court_time.dart';
import 'week_day.dart';

/// Tarifa por franja: precio por hora entre [start] y [end] los [days]
/// indicados. Si [end] es menor o igual, la franja cruza la medianoche.
class CourtRate extends Equatable {
  const CourtRate({
    required this.name,
    required this.pricePerHour,
    required this.days,
    required this.start,
    required this.end,
  });

  /// Máximo de tarifas por cancha que acepta la API.
  static const maxRates = 30;
  static const maxNameLength = 40;

  final String name;

  /// Pesos colombianos por hora.
  final int pricePerHour;
  final Set<WeekDay> days;
  final CourtTime start;
  final CourtTime end;

  bool get crossesMidnight => end.inMinutes <= start.inMinutes;

  /// Si esta tarifa y [other] cobran algún minuto de la semana en común
  /// (misma regla que la API, que las rechaza con 400).
  bool overlaps(CourtRate other) {
    for (final a in _weekIntervals()) {
      for (final b in other._weekIntervals()) {
        if (a.$1 < b.$2 && b.$1 < a.$2) return true;
      }
    }
    return false;
  }

  static const _weekMinutes = 7 * CourtTime.dayMinutes;

  /// Intervalos en minutos de la semana; la franja del domingo que pasa la
  /// medianoche continúa el lunes.
  List<(int, int)> _weekIntervals() {
    final span = CourtTime.span(start, end);
    return [
      for (final day in days)
        ...() {
          final from = day.index * CourtTime.dayMinutes + start.inMinutes;
          final to = from + span;
          return to <= _weekMinutes
              ? [(from, to)]
              : [(from, _weekMinutes), (0, to - _weekMinutes)];
        }(),
    ];
  }

  @override
  List<Object?> get props => [name, pricePerHour, days, start, end];
}
