import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/business_dashboard.dart';
import 'dashboard_cards.dart';

/// Colores de las dos clases de venta en todas las tarjetas.
Color get _walkInColor => AppColors.brandTeal;
const _consumptionColor = AppColors.amber500;

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
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
        label,
        style: AppTypography.bodySm.copyWith(color: AppColors.slate600),
      ),
    ],
  );
}

/// Barra apilada horizontal con las partes en proporción a su valor.
class _SplitBar extends StatelessWidget {
  const _SplitBar(this.parts);

  final List<(int, Color)> parts;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: ColoredBox(
          color: AppColors.slate100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (value, color) in parts)
                if (value > 0)
                  Expanded(
                    flex: value,
                    child: ColoredBox(color: color),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.emphasis = false});

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(color: AppColors.slate600),
          ),
        ),
        Text(
          value,
          style: AppTypography.labelMd.copyWith(
            color: emphasis ? AppColors.statusDeposit : AppColors.slate900,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

/// Lo vendido en el período, sueltas frente a consumos, y cuánto pesan las
/// ventas frente al valor de las canchas.
class SalesOverview extends StatelessWidget {
  const SalesOverview({super.key, required this.sales, required this.booked});

  final DashboardSales sales;

  /// Valor de las reservas confirmadas y jugadas del período.
  final int booked;

  @override
  Widget build(BuildContext context) {
    final total = sales.total.value.round();
    final generated = booked + total;
    final share = generated == 0 ? 0 : (total * 100 / generated).round();
    return DashboardCard(
      key: const Key('dashboard-sales'),
      icon: Icons.point_of_sale_outlined,
      title: 'Ventas de productos',
      subtitle: generated == 0
          ? null
          : 'Son el $share % de lo generado (canchas + ventas)',
      trailing: TrendChip(sales.total),
      child: sales.isEmpty
          ? const DashboardEmpty('Sin ventas en este período')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppFormatters.cop(total),
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${sales.count} ${sales.count == 1 ? 'venta' : 'ventas'} · '
                  '${sales.units} '
                  '${sales.units == 1 ? 'unidad' : 'unidades'}',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.slate500,
                  ),
                ),
                const SizedBox(height: 10),
                _SplitBar([
                  (sales.walkIn, _walkInColor),
                  (sales.consumptions, _consumptionColor),
                ]),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _Legend(
                      color: _walkInColor,
                      label: 'Sueltas ${AppFormatters.cop(sales.walkIn)}',
                    ),
                    _Legend(
                      color: _consumptionColor,
                      label:
                          'En reservas ${AppFormatters.cop(sales.consumptions)}',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _Line(
                  'Consumo promedio por reserva',
                  AppFormatters.cop(sales.averageConsumption),
                ),
                _Line(
                  'Consumos por cobrar',
                  AppFormatters.cop(sales.pendingConsumptions),
                  emphasis: sales.pendingConsumptions > 0,
                ),
              ],
            ),
    );
  }
}

/// Los productos que más dinero dejaron en el período.
class TopProductsList extends StatelessWidget {
  const TopProductsList({super.key, required this.products});

  final List<TopProduct> products;

  @override
  Widget build(BuildContext context) {
    final max = products.fold<int>(0, (m, p) => math.max(m, p.amount));
    final top = products.firstOrNull;
    return DashboardCard(
      key: const Key('dashboard-top-products'),
      icon: Icons.local_drink_outlined,
      title: 'Productos más vendidos',
      subtitle: top == null
          ? null
          : '${top.name}: ${top.units} '
                '${top.units == 1 ? 'unidad' : 'unidades'}',
      child: products.isEmpty
          ? const DashboardEmpty('Sin ventas en este período')
          : Column(
              children: [
                for (final (i, p) in products.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${p.name} · ${p.units} u.',
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.slate900,
                                  fontWeight: i == 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              AppFormatters.cop(p.amount),
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.slate700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _SplitBar([
                          (
                            p.amount,
                            i == 0
                                ? AppColors.brandTeal
                                : AppColors.brandTeal.withValues(alpha: 0.45),
                          ),
                          (max - p.amount, AppColors.slate100),
                        ]),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Ventas de cada día del período, apiladas: sueltas y consumos.
class SalesByDayBars extends StatelessWidget {
  const SalesByDayBars({super.key, required this.days});

  final List<SalesDay> days;

  static const _height = 70.0;

  static String _day(DateTime d) => '${d.day}/${d.month}';

  @override
  Widget build(BuildContext context) {
    final max = days.fold<int>(0, (m, d) => math.max(m, d.total));
    SalesDay? best;
    for (final day in days) {
      if (day.total > (best?.total ?? 0)) best = day;
    }
    // Con muchos días no caben las fechas: solo la primera y la última.
    final labelEvery = days.length <= 10;
    return DashboardCard(
      key: const Key('dashboard-sales-by-day'),
      icon: Icons.bar_chart_rounded,
      title: 'Ventas por día',
      subtitle: best == null
          ? null
          : 'El mejor día fue el ${AppFormatters.shortDate(best.date)} '
                '(${AppFormatters.cop(best.total)})',
      child: max == 0
          ? const DashboardEmpty('Sin ventas en este período')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: _height + 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final (i, day) in days.indexed)
                        Expanded(
                          child: Tooltip(
                            message:
                                '${AppFormatters.shortDate(day.date)}: '
                                'sueltas ${AppFormatters.cop(day.walkIn)} · '
                                'en reservas '
                                '${AppFormatters.cop(day.consumptions)}',
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: days.length > 40 ? 0.5 : 2,
                                  ),
                                  height: day.total == 0
                                      ? 2
                                      : math.max(4, _height * day.total / max),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate100,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (day.consumptions > 0)
                                        Expanded(
                                          flex: day.consumptions,
                                          child: const ColoredBox(
                                            color: _consumptionColor,
                                          ),
                                        ),
                                      if (day.walkIn > 0)
                                        Expanded(
                                          flex: day.walkIn,
                                          child: ColoredBox(
                                            color: _walkInColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 14,
                                  child:
                                      labelEvery ||
                                          i == 0 ||
                                          i == days.length - 1
                                      ? FittedBox(
                                          child: Text(
                                            _day(day.date),
                                            style: AppTypography.labelSm
                                                .copyWith(
                                                  color: AppColors.slate500,
                                                ),
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _Legend(color: _walkInColor, label: 'Sueltas'),
                    const _Legend(
                      color: _consumptionColor,
                      label: 'En reservas',
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
