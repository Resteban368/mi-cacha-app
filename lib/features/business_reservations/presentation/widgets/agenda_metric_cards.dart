import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/day_agenda.dart';

/// Barra / tarjetas de métricas y KPIs rápidos del día en la agenda:
/// - Ingresos Hoy (Total facturado/estimado)
/// - Cobrado en Caja (Anticipos y pagos completos)
/// - Por Cobrar Taquilla (Saldos pendientes)
class AgendaMetricCards extends StatelessWidget {
  const AgendaMetricCards({super.key, required this.agenda});

  final DayAgenda agenda;

  @override
  Widget build(BuildContext context) {
    final totalRevenue = agenda.collected + agenda.pending;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        final items = [
          _MetricItem(
            icon: Icons.payments_outlined,
            iconBg: AppColors.brandTealLight,
            iconFg: AppColors.brandTeal,
            title: 'Ingresos Hoy',
            value: '${AppFormatters.cop(totalRevenue)} COP',
            subtitle: '${agenda.totalCount} turnos programados',
            borderColor: AppColors.outlineVariant.withValues(alpha: 0.5),
            bgColor: AppColors.surfaceContainerLowest,
          ),
          _MetricItem(
            icon: Icons.point_of_sale_outlined,
            iconBg: AppColors.statusPaid.withValues(alpha: 0.15),
            iconFg: AppColors.statusPaid,
            title: 'Cobrado en Caja',
            value: '${AppFormatters.cop(agenda.collected)} COP',
            subtitle: '${(agenda.collectedRatio * 100).round()}% del total',
            borderColor: AppColors.statusPaid.withValues(alpha: 0.25),
            bgColor: AppColors.statusPaid.withValues(alpha: 0.05),
          ),
          _MetricItem(
            icon: agenda.pending > 0
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline_rounded,
            iconBg: agenda.pending > 0
                ? AppColors.statusDeposit.withValues(alpha: 0.2)
                : AppColors.brandTealLight,
            iconFg: agenda.pending > 0
                ? AppColors.statusDeposit
                : AppColors.brandTeal,
            title: 'Por Cobrar Taquilla',
            value: '${AppFormatters.cop(agenda.pending)} COP',
            subtitle: agenda.pending > 0
                ? 'Saldos pendientes de cobrar'
                : 'Todo cobrado',
            borderColor: agenda.pending > 0
                ? AppColors.statusDeposit.withValues(alpha: 0.3)
                : AppColors.outlineVariant.withValues(alpha: 0.5),
            bgColor: agenda.pending > 0
                ? AppColors.statusDeposit.withValues(alpha: 0.06)
                : AppColors.surfaceContainerLowest,
          ),
        ];

        if (isCompact) {
          return SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => SizedBox(width: 210, child: items[i]),
            ),
          );
        }

        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: items[i]),
            ],
          ],
        );
      },
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.borderColor,
    required this.bgColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String value;
  final String subtitle;
  final Color borderColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconFg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
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
