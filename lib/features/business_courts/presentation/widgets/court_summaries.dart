import '../../../../core/domain/entities/sport.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/court_schedule.dart';
import 'court_pricing_card.dart';
import 'court_rates_section.dart';

/// Textos cortos para describir una cancha en listas y diálogos.
abstract final class CourtSummaries {
  static String sport(Sport? sport) => switch (sport) {
    Sport.futbol => 'Fútbol',
    Sport.padel => 'Pádel',
    Sport.baloncesto => 'Baloncesto',
    Sport.voleibol => 'Voleibol',
    null => 'Otro deporte',
  };

  /// `Lun a Sáb · 06:00–23:00`, o los días abiertos si las horas varían.
  static String schedule(List<DaySchedule> schedules) {
    final open = schedules.where((s) => s.isOpen).toList();
    if (open.isEmpty) return 'Cerrada toda la semana';
    final days = CourtRatesSection.daysLabel({for (final s in open) s.day});
    final first = open.first;
    final sameHours = open.every(
      (s) => s.open == first.open && s.close == first.close,
    );
    if (!sameHours) return '$days · horarios variados';
    return '$days · ${first.open!.label}–${first.close!.label}'
        '${first.closesNextDay ? ' (día sig.)' : ''}';
  }

  /// `$89.900/h · turnos de 1 h`
  static String pricing(Court court) =>
      '${AppFormatters.cop(court.basePricePerHour)}/h · turnos de '
      '${CourtPricingCard.durationLabel(court.slotDuration)}';

  static String rates(int count) => switch (count) {
    0 => 'Sin tarifas por franja',
    1 => '1 tarifa por franja',
    _ => '$count tarifas por franja',
  };
}
