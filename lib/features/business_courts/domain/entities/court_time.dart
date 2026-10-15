import 'package:equatable/equatable.dart';

/// Hora local del día (`HH:mm`) para horarios y tarifas de la cancha.
class CourtTime extends Equatable implements Comparable<CourtTime> {
  const CourtTime(this.hour, [this.minute = 0])
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  static const dayMinutes = 24 * 60;

  final int hour;
  final int minute;

  int get inMinutes => hour * 60 + minute;

  /// `06:00`: formato que acepta la API.
  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// `null` si el texto no tiene formato `HH:mm`.
  static CourtTime? tryParse(String? text) {
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(text ?? '');
    if (match == null) return null;
    return CourtTime(int.parse(match[1]!), int.parse(match[2]!));
  }

  /// Minutos de una franja; si [end] es menor o igual termina al día
  /// siguiente (iguales = 24 h), igual que en la API.
  static int span(CourtTime start, CourtTime end) {
    final diff = (end.inMinutes - start.inMinutes) % dayMinutes;
    return diff == 0 ? dayMinutes : diff;
  }

  @override
  int compareTo(CourtTime other) => inMinutes.compareTo(other.inMinutes);

  @override
  List<Object?> get props => [hour, minute];
}
