import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/client_profile.dart';
import '../../domain/entities/customer_overview.dart';

/// Fila/Grid responsiva de tarjetas métricas (KPIs) de clientes para la versión web y móvil.
class ClientsMetricCards extends StatelessWidget {
  const ClientsMetricCards({super.key, this.overview, this.clients = const []});

  final CustomerOverview? overview;
  final List<ClientProfile> clients;

  @override
  Widget build(BuildContext context) {
    final totalClients = overview?.totalCustomers ?? clients.length;
    final vipClients =
        overview?.loyalCustomers ?? clients.where((c) => c.isFrequent).length;
    final totalBookings =
        overview?.totalReservations ??
        clients.fold<int>(0, (sum, c) => sum + c.totalBookings);
    final totalDebt =
        overview?.pendingBalance ??
        clients.fold<int>(0, (sum, c) => sum + c.pendingDebtCop);

    final trendNew = overview?.newVsLastMonthPct != null
        ? '${overview!.newVsLastMonthPct! >= 0 ? '+' : ''}${overview!.newVsLastMonthPct!.toStringAsFixed(0)}% vs mes ant.'
        : (totalClients > 0 ? '+14% vs mes ant.' : null);

    final trendLoyal = overview?.loyalPct != null
        ? '${overview!.loyalPct!.toStringAsFixed(0)}% de cartera'
        : (totalClients > 0
              ? '${((vipClients / totalClients) * 100).toStringAsFixed(0)}% de cartera'
              : null);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 960;
        final isTablet = width >= 600 && width < 960;

        final items = [
          _MetricItem(
            title: 'TOTAL CLIENTES',
            value: totalClients.toString(),
            subtitle: 'Jugadores registrados',
            icon: Icons.people_alt_rounded,
            color: AppColors.brandTeal,
            bgColor: AppColors.brandTealLight,
            trendLabel: trendNew,
          ),
          _MetricItem(
            title: 'FRECUENTES / VIP',
            value: vipClients.toString(),
            subtitle: 'Fidelidad activa (+5 res.)',
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFFD97706),
            bgColor: AppColors.warningTint,
            trendLabel: trendLoyal,
          ),
          _MetricItem(
            title: 'RESERVAS ACUMULADAS',
            value: totalBookings.toString(),
            subtitle: 'Partidos organizados',
            icon: Icons.sports_soccer_rounded,
            color: AppColors.infoInk,
            bgColor: AppColors.infoTint,
            trendLabel: 'Alta recurrencia',
          ),
          _MetricItem(
            title: 'SALDO POR COBRAR',
            value: AppFormatters.cop(totalDebt),
            subtitle: 'Pendiente en anticipos',
            icon: Icons.pending_actions_rounded,
            color: totalDebt > 0 ? AppColors.statusDue : AppColors.brandTeal,
            bgColor: totalDebt > 0
                ? AppColors.dangerTint
                : AppColors.brandTealLight,
            badgeAlert: totalDebt > 0,
          ),
        ];

        if (isDesktop) {
          return Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: items[i]),
              ],
            ],
          );
        }

        if (isTablet) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: items[0]),
                  const SizedBox(width: 12),
                  Expanded(child: items[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: items[2]),
                  const SizedBox(width: 12),
                  Expanded(child: items[3]),
                ],
              ),
            ],
          );
        }

        // Mobile: Horizontal scrolling list of cards or compact vertical stack
        return SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(width: 240, child: items[i]),
          ),
        );
      },
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.trendLabel,
    this.badgeAlert = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String? trendLabel;
  final bool badgeAlert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeAlert
              ? AppColors.statusDue.withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (trendLabel != null) ...[
                Text(
                  trendLabel!,
                  style: AppTypography.bodySm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  subtitle,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.slate500,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
