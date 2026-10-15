/// Formatos locales (Colombia) definidos en el design system:
/// - Moneda: `$90.000` (punto de miles, sin decimales).
/// - Hora: `6:30 p. m.` (12 h, minúsculas con puntos).
abstract final class AppFormatters {
  static const _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// `90000` → `$90.000`
  static String cop(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return '${value < 0 ? '-' : ''}\$$buffer';
  }

  /// Formato compacto para indicadores: `640000` → `$640K`, `1250000` → `$1,3M`.
  static String copCompact(int value) {
    if (value >= 1000000) {
      final millions = value / 1000000;
      final text = millions == millions.roundToDouble()
          ? millions.toStringAsFixed(0)
          : millions.toStringAsFixed(1).replaceAll('.', ',');
      return '\$${text}M';
    }
    if (value >= 1000) return '\$${(value / 1000).round()}K';
    return cop(value);
  }

  static String _meridiem(DateTime t) => t.hour < 12 ? 'a. m.' : 'p. m.';

  static String _clock(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$hour:${t.minute.toString().padLeft(2, '0')}';
  }

  /// `19:15` → `7:15 p. m.`
  static String time(DateTime t) => '${_clock(t)} ${_meridiem(t)}';

  /// `4:30 – 6:00 p. m.` (el meridiano se repite solo si cambia).
  static String timeRange(DateTime start, DateTime end) {
    if (_meridiem(start) == _meridiem(end)) {
      return '${_clock(start)} – ${_clock(end)} ${_meridiem(end)}';
    }
    return '${time(start)} – ${time(end)}';
  }

  /// `1h 30m`, `1h`, `45m`
  static String duration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// `Jueves, 9 de octubre de 2026`
  static String longDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${d.day} de ${_months[d.month - 1]} '
      'de ${d.year}';

  /// `hace 5 min`, `hace 2 h`, `ayer`, `hace 3 días`.
  static String relative(DateTime from, DateTime now) {
    final diff = now.difference(from);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    return 'hace ${diff.inDays} días';
  }

  /// `9 oct`
  static String shortDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1].substring(0, 3)}';

  /// `15 sep. 2026`
  static String mediumDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1].substring(0, 3)}. ${d.year}';
}
