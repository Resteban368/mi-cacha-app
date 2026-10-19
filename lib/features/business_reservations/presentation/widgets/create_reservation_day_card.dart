import 'package:flutter/material.dart';

import '../../../../core/domain/entities/sport.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../business_courts/presentation/widgets/court_summaries.dart';
import 'reservation_section_card.dart';
import 'sport_style.dart';

/// "1. Deporte y fecha del turno": deporte (obligatorio) y una tira de 7
/// días alrededor del elegido; el día mínimo es hoy. Con un solo deporte no
/// se muestra el selector.
class CreateReservationDayCard extends StatelessWidget {
  const CreateReservationDayCard({
    super.key,
    required this.sports,
    required this.sport,
    required this.day,
    required this.minDay,
    required this.onSportChanged,
    required this.onDayChanged,
  });

  final List<Sport> sports;
  final Sport? sport;
  final DateTime day;
  final DateTime minDay;
  final ValueChanged<Sport> onSportChanged;
  final ValueChanged<DateTime> onDayChanged;

  static const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: minDay,
      lastDate: minDay.add(const Duration(days: 365)),
      helpText: 'Día de la reserva',
    );
    if (picked != null) onDayChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final showSports = sports.length > 1;
    return ReservationSectionCard(
      icon: Icons.emoji_events_outlined,
      title: showSports ? '1. Deporte y fecha del turno' : '1. Fecha del turno',
      compact: true,
      trailing: OutlinedButton.icon(
        key: const Key('pick-date'),
        onPressed: () => _pickDate(context),
        icon: const Icon(Icons.calendar_month_outlined, size: 16),
        label: const Text('Ver mes completo'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandTeal,
          backgroundColor: AppColors.surface,
          side: BorderSide(color: AppColors.brandTeal.withValues(alpha: 0.2)),
          visualDensity: VisualDensity.compact,
          textStyle: AppTypography.labelMd.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final strip = _DayStrip(
            day: day,
            minDay: minDay,
            onDayChanged: onDayChanged,
          );
          if (!showSports) return strip;
          final pills = [
            for (final s in sports)
              _SportPill(
                key: Key('sport-${s.apiCode}'),
                sport: s,
                selected: s == sport,
                onTap: () => onSportChanged(s),
              ),
          ];
          // Web: deportes y días en una sola fila.
          if (constraints.maxWidth >= 760) {
            return Row(
              children: [
                Wrap(spacing: 8, runSpacing: 8, children: pills),
                const SizedBox(width: 16),
                Expanded(child: strip),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(spacing: 8, children: pills),
              ),
              const SizedBox(height: 10),
              strip,
            ],
          );
        },
      ),
    );
  }
}

class _SportPill extends StatelessWidget {
  const _SportPill({
    super.key,
    required this.sport,
    required this.selected,
    required this.onTap,
  });

  final Sport sport;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.brandTeal : AppColors.slate100,
        borderRadius: BorderRadius.circular(12),
        elevation: selected ? 1 : 0,
        shadowColor: AppColors.brandTeal.withValues(alpha: 0.3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sport.icon,
                  size: 18,
                  color: selected ? AppColors.accentLime : AppColors.slate500,
                ),
                const SizedBox(width: 8),
                Text(
                  CourtSummaries.sport(sport),
                  style: AppTypography.labelLg.copyWith(
                    color: selected ? AppColors.onPrimary : AppColors.slate700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Siete días con el elegido cerca del centro; los pasados, deshabilitados.
class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.day,
    required this.minDay,
    required this.onDayChanged,
  });

  final DateTime day;
  final DateTime minDay;
  final ValueChanged<DateTime> onDayChanged;

  @override
  Widget build(BuildContext context) {
    final isMinDay = CreateReservationDayCard._sameDay(day, minDay);
    return LayoutBuilder(
      builder: (context, constraints) {
        // En pantallas angostas caben menos días.
        final count = constraints.maxWidth >= 520 ? 7 : 5;
        final before = count ~/ 2 - 1;
        final first = DateTime(day.year, day.month, day.day - before);
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.slate200.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Día anterior',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left, size: 20),
                color: AppColors.slate600,
                // No se reserva en días pasados.
                onPressed: isMinDay
                    ? null
                    : () => onDayChanged(
                        DateTime(day.year, day.month, day.day - 1),
                      ),
              ),
              for (var i = 0; i < count; i++)
                Expanded(
                  child: _DayCell(
                    date: DateTime(first.year, first.month, first.day + i),
                    selected: i == before,
                    // El día mínimo es hoy.
                    isToday: CreateReservationDayCard._sameDay(
                      DateTime(first.year, first.month, first.day + i),
                      minDay,
                    ),
                    enabled: !DateTime(
                      first.year,
                      first.month,
                      first.day + i,
                    ).isBefore(minDay),
                    onTap: onDayChanged,
                  ),
                ),
              IconButton(
                tooltip: 'Día siguiente',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right, size: 20),
                color: AppColors.slate600,
                onPressed: () =>
                    onDayChanged(DateTime(day.year, day.month, day.day + 1)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.enabled,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool isToday;
  final bool enabled;
  final ValueChanged<DateTime> onTap;

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

  @override
  Widget build(BuildContext context) {
    final weekday = CreateReservationDayCard._weekdays[date.weekday - 1];
    final label = '$weekday ${date.day} de ${_months[date.month - 1]}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Semantics(
        button: enabled,
        selected: selected,
        label: isToday ? '$label, hoy' : label,
        excludeSemantics: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              key: selected ? const Key('reservation-day') : null,
              color: selected ? AppColors.brandTeal : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: enabled && !selected ? () => onTap(date) : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Text(
                        weekday.toUpperCase(),
                        style: AppTypography.labelSm.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.accentLime
                              : AppColors.slate400,
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: AppTypography.labelLg.copyWith(
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: selected
                              ? AppColors.onPrimary
                              : enabled
                              ? AppColors.slate700
                              : AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Hoy: punto lima.
            if (isToday)
              Positioned(
                top: -3,
                right: -1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.accentLime,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.onPrimary, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
