import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pulsing_dot.dart';
import '../../domain/entities/day_agenda.dart';
import '../../domain/entities/reservation_filter.dart';

/// Filtros rápidos con conteo; tocar el activo lo desactiva.
class ReservationFilterChips extends StatelessWidget {
  const ReservationFilterChips({
    super.key,
    required this.agenda,
    required this.selected,
    required this.onToggle,
  });

  final DayAgenda agenda;
  final ReservationFilter? selected;
  final ValueChanged<ReservationFilter> onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          for (final filter in ReservationFilter.values) ...[
            if (filter.index > 0) const SizedBox(width: 6),
            _FilterChip(
              filter: filter,
              count: agenda.countFor(filter),
              selected: filter == selected,
              onTap: () => onToggle(filter),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final ReservationFilter filter;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, icon, iconColor, badgeBg, badgeFg) = switch (filter) {
      ReservationFilter.live => (
        'En vivo',
        Icons.bolt,
        AppColors.brandTeal,
        AppColors.accentLime,
        AppColors.inverseSurface,
      ),
      ReservationFilter.upcoming => (
        'Próximas',
        Icons.schedule,
        AppColors.primary,
        AppColors.surfaceContainerHigh,
        AppColors.onSurfaceVariant,
      ),
      ReservationFilter.finished => (
        'Terminadas',
        Icons.check_circle_outline,
        AppColors.brandTeal,
        AppColors.brandTealLight,
        AppColors.brandTeal,
      ),
      ReservationFilter.noShow => (
        'No asistió',
        Icons.cancel_outlined,
        AppColors.statusDue,
        AppColors.errorContainer,
        AppColors.onErrorContainer,
      ),
      ReservationFilter.cancelled => (
        'Canceladas',
        Icons.event_busy_rounded,
        AppColors.statusDue,
        AppColors.surfaceContainerHigh,
        AppColors.onSurfaceVariant,
      ),
    };

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppColors.brandTealLight
            : AppColors.surfaceContainerLow,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.brandTeal : Colors.transparent,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (filter == ReservationFilter.live && count > 0) ...[
                  const PulsingDot(),
                  const SizedBox(width: 6),
                ],
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: AppTypography.labelSm.copyWith(
                      color: badgeFg,
                      fontSize: 10,
                    ),
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
