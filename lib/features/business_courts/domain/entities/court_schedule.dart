import 'package:equatable/equatable.dart';

import 'court_time.dart';
import 'week_day.dart';

/// Horario de un día. Si [close] es menor o igual que [open], la cancha
/// cierra al día siguiente (p. ej. 18:00 → 02:00).
class DaySchedule extends Equatable {
  const DaySchedule.closed(this.day) : open = null, close = null;

  const DaySchedule.open(
    this.day, {
    required CourtTime this.open,
    required CourtTime this.close,
  });

  final WeekDay day;
  final CourtTime? open;
  final CourtTime? close;

  bool get isOpen => open != null && close != null;

  bool get closesNextDay => isOpen && close!.inMinutes <= open!.inMinutes;

  /// Semana por defecto al crear una cancha: todos los días de 06:00 a 22:00.
  static List<DaySchedule> defaultWeek() => [
    for (final day in WeekDay.values)
      DaySchedule.open(
        day,
        open: const CourtTime(6),
        close: const CourtTime(22),
      ),
  ];

  @override
  List<Object?> get props => [day, open, close];
}
