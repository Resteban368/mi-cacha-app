import 'package:flutter/material.dart';

import '../../../../core/domain/entities/sport.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../business_courts/domain/entities/court.dart';
import '../../../business_courts/presentation/widgets/court_summaries.dart';
import '../../domain/entities/business_dashboard.dart';

/// Período (Hoy, 7 días, 30 días, Este mes o un rango), deporte y cancha.
class DashboardFiltersBar extends StatelessWidget {
  const DashboardFiltersBar({
    super.key,
    required this.filter,
    required this.period,
    required this.sports,
    required this.courts,
    required this.onChanged,
    required this.today,
  });

  final DashboardFilter filter;

  /// Fechas que resolvió la API (para mostrar el rango y el anterior).
  final DashboardPeriodInfo? period;
  final List<Sport> sports;
  final List<Court> courts;
  final ValueChanged<DashboardFilter> onChanged;
  final DateTime today;

  Future<void> _pickRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 3),
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: filter.from != null && filter.to != null
          ? DateTimeRange(start: filter.from!, end: filter.to!)
          : DateTimeRange(
              start: today.subtract(const Duration(days: 6)),
              end: today,
            ),
      locale: const Locale('es', 'CO'),
      helpText: 'Período del dashboard',
    );
    if (range == null) return;
    onChanged(
      filter.copyWith(
        period: DashboardPeriod.custom,
        from: () => range.start,
        to: () => range.end,
      ),
    );
  }

  static String _range(DateTime from, DateTime to) => from == to
      ? AppFormatters.shortDate(from)
      : '${AppFormatters.shortDate(from)} – ${AppFormatters.shortDate(to)}';

  @override
  Widget build(BuildContext context) {
    final period = this.period;
    final courtName = courts
        .where((c) => c.id == filter.courtId)
        .firstOrNull
        ?.name;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final p in DashboardPeriod.values)
                _Pill(
                  key: Key('period-${p.apiCode}'),
                  label:
                      p == DashboardPeriod.custom &&
                          filter.period == p &&
                          filter.from != null &&
                          filter.to != null
                      ? _range(filter.from!, filter.to!)
                      : p.label,
                  icon: p == DashboardPeriod.custom
                      ? Icons.date_range_outlined
                      : null,
                  selected: filter.period == p,
                  onTap: () => p == DashboardPeriod.custom
                      ? _pickRange(context)
                      : onChanged(filter.copyWith(period: p)),
                ),
              if (sports.length > 1)
                _MenuPill<Sport?>(
                  key: const Key('filter-sport'),
                  icon: Icons.sports_soccer,
                  label: filter.sport == null
                      ? 'Todos los deportes'
                      : CourtSummaries.sport(filter.sport),
                  active: filter.sport != null,
                  options: [
                    (null, 'Todos los deportes'),
                    for (final s in sports) (s, CourtSummaries.sport(s)),
                  ],
                  onSelected: (sport) =>
                      onChanged(filter.copyWith(sport: () => sport)),
                ),
              if (courts.isNotEmpty)
                _MenuPill<String?>(
                  key: const Key('filter-court'),
                  icon: Icons.stadium_outlined,
                  label: courtName ?? 'Todas las canchas',
                  active: courtName != null,
                  options: [
                    (null, 'Todas las canchas'),
                    for (final c in courts) (c.id, c.name),
                  ],
                  onSelected: (id) =>
                      onChanged(filter.copyWith(courtId: () => id)),
                ),
            ],
          ),
          if (period != null) ...[
            const SizedBox(height: 6),
            Text(
              '${_range(period.from, period.to)} · ${period.days} '
              '${period.days == 1 ? 'día' : 'días'} · comparado con '
              '${_range(period.previousFrom, period.previousTo)}',
              key: const Key('dashboard-period'),
              style: AppTypography.bodySm.copyWith(
                color: AppColors.slate500,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.brandTeal : AppColors.slate100,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon case final icon?) ...[
                  Icon(
                    icon,
                    size: 15,
                    color: selected ? AppColors.accentLime : AppColors.slate500,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: AppTypography.labelMd.copyWith(
                    color: selected ? AppColors.onPrimary : AppColors.slate700,
                    fontWeight: FontWeight.w700,
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

class _MenuPill<T> extends StatelessWidget {
  const _MenuPill({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.options,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final bool active;
  final List<(T, String)> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: label,
      onSelected: (i) => onSelected(options[i].$1),
      itemBuilder: (context) => [
        for (final (i, option) in options.indexed)
          PopupMenuItem(value: i, child: Text(option.$2)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? AppColors.brandTealLight
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.brandTeal : AppColors.slate200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.brandTeal),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.slate700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: AppColors.slate500,
            ),
          ],
        ),
      ),
    );
  }
}
