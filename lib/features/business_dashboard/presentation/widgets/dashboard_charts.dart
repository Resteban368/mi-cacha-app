import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../business_courts/presentation/widgets/court_summaries.dart';
import '../../../business_reservations/presentation/widgets/sport_style.dart';
import '../../domain/entities/business_dashboard.dart';
import 'dashboard_cards.dart';

String _pct(num value) {
  final rounded = value.round();
  return value == rounded ? '$rounded %' : '${value.toStringAsFixed(1)} %';
}

String _hours(num value) {
  final rounded = value.round();
  return value == rounded ? '$rounded h' : '${value.toStringAsFixed(1)} h';
}

/// Barra horizontal de progreso con fondo gris.
class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, this.color});

  final double fraction;
  final Color? color;

  Color get _color => color ?? AppColors.brandTeal;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: ColoredBox(
          color: AppColors.slate100,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction.clamp(0, 1).toDouble(),
            heightFactor: 1,
            child: ColoredBox(color: _color),
          ),
        ),
      ),
    );
  }
}

/// Reservas por estado: barra apilada y leyenda con cantidades.
class ReservationStatusBreakdown extends StatelessWidget {
  const ReservationStatusBreakdown({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final parts = [
      ('Confirmadas', summary.confirmed, AppColors.brandTeal),
      ('Jugadas', summary.completed, AppColors.emerald600),
      ('No asistió', summary.noShow, AppColors.amber500),
      ('Canceladas', summary.cancelled, AppColors.statusDue),
    ];
    final total = parts.fold<int>(0, (sum, p) => sum + p.$2);
    return DashboardCard(
      icon: Icons.donut_large_outlined,
      title: 'Estado de las reservas',
      subtitle:
          'Cancelación ${_pct(summary.cancellationRate)} · '
          'No asistencia ${_pct(summary.noShowRate)}',
      child: total == 0
          ? const DashboardEmpty('Sin reservas en este período')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (_, count, color) in parts)
                          if (count > 0)
                            Expanded(
                              flex: count,
                              child: ColoredBox(color: color),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    for (final (label, count, color) in parts)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$label $count',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// Ocupación de cada cancha sobre sus horas abiertas.
class CourtOccupancyList extends StatelessWidget {
  const CourtOccupancyList({super.key, required this.courts});

  final List<CourtOccupancy> courts;

  @override
  Widget build(BuildContext context) {
    final sorted = [...courts]
      ..sort((a, b) => b.occupancyPct.compareTo(a.occupancyPct));
    return DashboardCard(
      icon: Icons.stadium_outlined,
      title: 'Ocupación por cancha',
      subtitle: 'Horas reservadas sobre las horas abiertas',
      child: sorted.isEmpty
          ? const DashboardEmpty('No hay canchas con este filtro')
          : Column(
              children: [
                for (final court in sorted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              court.sport?.icon ?? Icons.stadium_outlined,
                              size: 14,
                              color: AppColors.slate500,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                court.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.slate900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _pct(court.occupancyPct),
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.brandTeal,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _Bar(fraction: court.occupancyPct / 100),
                        const SizedBox(height: 2),
                        Text(
                          '${court.reservations} reservas · '
                          '${_hours(court.bookedHours)} de '
                          '${_hours(court.openHours)} · '
                          '${AppFormatters.cop(court.booked)}',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.slate500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Reservas por día de la semana (de lunes a domingo), con el día de más
/// movimiento resaltado.
class WeekdayBars extends StatelessWidget {
  const WeekdayBars({super.key, required this.days, required this.busiest});

  final List<WeekdayStat> days;
  final WeekdayStat? busiest;

  static const _height = 70.0;

  @override
  Widget build(BuildContext context) {
    final max = days.fold<int>(0, (m, d) => math.max(m, d.reservations));
    final busiest = this.busiest;
    return DashboardCard(
      icon: Icons.calendar_view_week_outlined,
      title: 'Días con más movimiento',
      subtitle: busiest == null
          ? null
          : 'El ${busiest.day.label.toLowerCase()} es el día con más '
                'reservas',
      child: max == 0
          ? const DashboardEmpty('Sin reservas en este período')
          : SizedBox(
              height: _height + 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in days)
                    Expanded(
                      child: Tooltip(
                        message:
                            '${day.day.label}: ${day.reservations} reservas · '
                            '${AppFormatters.cop(day.booked)}',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${day.reservations}',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.slate600,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              key: Key('weekday-bar-${day.day.apiCode}'),
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              height: math.max(
                                4,
                                _height * day.reservations / max,
                              ),
                              decoration: BoxDecoration(
                                color: day.day == busiest?.day
                                    ? AppColors.brandTeal
                                    : AppColors.brandTeal.withValues(
                                        alpha: 0.35,
                                      ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              day.day.short,
                              style: AppTypography.labelSm.copyWith(
                                color: day.day == busiest?.day
                                    ? AppColors.brandTeal
                                    : AppColors.slate500,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Mapa de calor día × hora: más oscuro = más reservas (escala con
/// `heatmapMax`).
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({super.key, required this.dashboard});

  final BusinessDashboard dashboard;

  static const _cell = 22.0;
  static const _labelWidth = 34.0;

  static String _hourLabel(int hour) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h${hour < 12 ? 'a' : 'p'}';
  }

  @override
  Widget build(BuildContext context) {
    final hours = dashboard.heatmapHours;
    final busiest = dashboard.busiestSlot;
    final max = dashboard.heatmapMax == 0 ? 1 : dashboard.heatmapMax;
    return DashboardCard(
      icon: Icons.grid_on_outlined,
      title: 'Horarios con más movimiento',
      subtitle: busiest == null
          ? null
          : 'Hora pico: ${busiest.day.label.toLowerCase()} a las '
                '${AppFormatters.time(DateTime(2000, 1, 1, busiest.hour))}'
                ' (${busiest.reservations} reservas)',
      child: hours == null
          ? const DashboardEmpty('Sin reservas en este período')
          : LayoutBuilder(
              builder: (context, constraints) {
                final (first, last) = hours;
                final count = last - first + 1;
                // Las celdas se estiran para llenar el ancho; si no caben,
                // la grilla se desplaza en horizontal.
                final cell = math.max(
                  _cell,
                  (constraints.maxWidth - _labelWidth) / count,
                );
                final grid = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final day in Weekday.values)
                      Row(
                        children: [
                          SizedBox(
                            width: _labelWidth,
                            child: Text(
                              day.short,
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.slate500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          for (var h = first; h <= last; h++)
                            _HeatCell(
                              size: cell,
                              count: dashboard.reservationsAt(day, h),
                              max: max,
                              label: '${day.label} ${_hourLabel(h)}',
                            ),
                        ],
                      ),
                    Row(
                      children: [
                        const SizedBox(width: _labelWidth),
                        for (var h = first; h <= last; h++)
                          SizedBox(
                            width: cell,
                            child: Text(
                              _hourLabel(h),
                              textAlign: TextAlign.center,
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.slate400,
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: grid,
                );
              },
            ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.size,
    required this.count,
    required this.max,
    required this.label,
  });

  final double size;
  final int count;
  final int max;
  final String label;

  @override
  Widget build(BuildContext context) {
    final intensity = count / max;
    final color = count == 0
        ? AppColors.slate100
        : Color.lerp(
            AppColors.brandTeal.withValues(alpha: 0.18),
            AppColors.brandTealDeep,
            intensity,
          )!;
    return Tooltip(
      message: '$label: $count ${count == 1 ? 'reserva' : 'reservas'}',
      child: Container(
        width: size - 3,
        height: _cellHeight,
        margin: const EdgeInsets.all(1.5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: count == 0
            ? null
            : Text(
                '$count',
                style: AppTypography.labelSm.copyWith(
                  color: intensity > 0.45
                      ? AppColors.onPrimary
                      : AppColors.brandTealDeep,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
      ),
    );
  }

  static const _cellHeight = 16.0;
}

/// Los 5 clientes con más reservas y lo que han pagado.
class TopCustomersList extends StatelessWidget {
  const TopCustomersList({super.key, required this.customers, this.onTap});

  final List<TopCustomer> customers;
  final ValueChanged<TopCustomer>? onTap;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      icon: Icons.emoji_events_outlined,
      title: 'Clientes más frecuentes',
      subtitle: 'Por número de reservas',
      child: customers.isEmpty
          ? const DashboardEmpty('Sin reservas en este período')
          : Column(
              children: [
                for (final (i, c) in customers.take(5).indexed)
                  InkWell(
                    onTap: onTap == null ? null : () => onTap!(c),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? AppColors.accentLime
                                  : AppColors.slate100,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.slate900,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelMd.copyWith(
                                    color: AppColors.slate900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (c.phone.isNotEmpty)
                                  Text(
                                    c.phone,
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.slate500,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${c.reservations} '
                                '${c.reservations == 1 ? 'reserva' : 'reservas'}',
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.brandTeal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                AppFormatters.cop(c.paid),
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.slate500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Métodos de pago de mayor a menor monto, con su % del total cobrado.
class PaymentMethodsList extends StatelessWidget {
  const PaymentMethodsList({super.key, required this.methods});

  final List<PaymentMethodStat> methods;

  @override
  Widget build(BuildContext context) {
    final top = methods.firstOrNull;
    return DashboardCard(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Métodos de pago',
      subtitle: top == null
          ? null
          : '${top.name} es la plataforma con más pagos (${_pct(top.pct)})',
      child: methods.isEmpty
          ? const DashboardEmpty('Sin pagos aprobados en este período')
          : Column(
              children: [
                for (final (i, m) in methods.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${m.name} · ${m.count} '
                                '${m.count == 1 ? 'pago' : 'pagos'}',
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.slate900,
                                  fontWeight: i == 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${AppFormatters.cop(m.amount)} · ${_pct(m.pct)}',
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.slate700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _Bar(
                          fraction: m.pct / 100,
                          color: i == 0
                              ? AppColors.brandTeal
                              : AppColors.brandTeal.withValues(alpha: 0.45),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Reservas y valor por deporte.
class SportsBreakdown extends StatelessWidget {
  const SportsBreakdown({super.key, required this.sports});

  final List<SportStat> sports;

  @override
  Widget build(BuildContext context) {
    final total = sports.fold<int>(0, (sum, s) => sum + s.reservations);
    return DashboardCard(
      icon: Icons.sports_soccer_outlined,
      title: 'Reservas por deporte',
      child: sports.isEmpty || total == 0
          ? const DashboardEmpty('Sin reservas en este período')
          : Column(
              children: [
                for (final s in sports)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(s.sport.icon, size: 16, color: s.sport.color),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                CourtSummaries.sport(s.sport),
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.slate900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${s.reservations} · '
                              '${AppFormatters.cop(s.booked)}',
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.slate600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _Bar(
                          fraction: s.reservations / total,
                          color: s.sport.color,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
