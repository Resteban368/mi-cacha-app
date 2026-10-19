import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/business_dashboard.dart';

/// Tarjeta blanca de una sección del dashboard: ícono, título, subtítulo
/// opcional y contenido.
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200.withValues(alpha: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.brandTealLight,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: AppColors.brandTeal),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLg.copyWith(
                        color: AppColors.slate900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle case final subtitle?)
                      Text(
                        subtitle,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.slate500,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Variación frente al período anterior: ▲ 12 % en verde, ▼ en rojo y
/// "—" si el anterior fue 0. Con [lowerIsBetter] los colores se invierten.
class TrendChip extends StatelessWidget {
  const TrendChip(this.trend, {super.key, this.lowerIsBetter = false});

  final Trend trend;
  final bool lowerIsBetter;

  static String label(double? pct) {
    if (pct == null) return '—';
    final value = pct.abs();
    final text = value >= 10 || value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1).replaceAll('.', ',');
    return '$text %';
  }

  @override
  Widget build(BuildContext context) {
    final pct = trend.changePct;
    final good = pct == null || pct == 0 ? null : (pct > 0) != lowerIsBetter;
    final (background, foreground) = switch (good) {
      null => (AppColors.slate100, AppColors.slate500),
      true => (AppColors.emerald50, AppColors.emerald800),
      false => (const Color(0xFFFEF2F2), AppColors.statusDue),
    };
    return Tooltip(
      message: pct == null
          ? 'Sin datos del período anterior'
          : 'Frente al período anterior',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pct != null && pct != 0)
              Icon(
                pct > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 11,
                color: foreground,
              ),
            Text(
              label(pct),
              style: AppTypography.labelSm.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicador principal: etiqueta, valor grande, variación y un detalle.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trend,
    this.detail,
    this.accent = AppColors.brandTeal,
    this.lowerIsBetter = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Trend? trend;
  final String? detail;
  final Color accent;
  final bool lowerIsBetter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trend = this.trend;
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.slate200.withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.slate900,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  if (trend != null) ...[
                    const SizedBox(width: 6),
                    TrendChip(trend, lowerIsBetter: lowerIsBetter),
                  ],
                ],
              ),
              if (detail case final detail?) ...[
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.slate500,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Mensaje centrado para secciones sin datos.
class DashboardEmpty extends StatelessWidget {
  const DashboardEmpty(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.bodySm.copyWith(color: AppColors.slate400),
      ),
    ),
  );
}
