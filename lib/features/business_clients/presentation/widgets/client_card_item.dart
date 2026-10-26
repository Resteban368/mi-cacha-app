import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/client_profile.dart';

/// Tarjeta táctil de cliente para móvil y vistas reducidas.
class ClientCardItem extends StatelessWidget {
  const ClientCardItem({
    super.key,
    required this.client,
    required this.onTap,
    required this.onWhatsAppTap,
    required this.onNewReservationTap,
    required this.onHistoryTap,
  });

  final ClientProfile client;
  final VoidCallback onTap;
  final VoidCallback onWhatsAppTap;
  final VoidCallback onNewReservationTap;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top: Avatar + Name + Tier Badge
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: client.isVip
                              ? [
                                  const Color(0xFFF59E0B),
                                  const Color(0xFFD97706),
                                ]
                              : [AppColors.brandTeal, AppColors.brandTealDeep],
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        client.initials,
                        style: AppTypography.labelMd.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.name,
                            style: AppTypography.bodyLg.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            client.documentId.isNotEmpty
                                ? 'C.C. ${client.documentId}'
                                : 'Sin cédula registrada',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.slate500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _TierBadgeCompact(tier: client.tier),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(height: 1, thickness: 1, color: AppColors.slate100),
                const SizedBox(height: 12),

                // Middle: Metrics summary row
                Row(
                  children: [
                    Expanded(
                      child: _MetricPill(
                        label: 'Reservas',
                        value: '${client.totalBookings}',
                        sub:
                            '${client.attendanceRate.toStringAsFixed(0)}% asis.',
                        icon: Icons.sports_soccer_rounded,
                        color: AppColors.brandTeal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricPill(
                        label: 'Inversión',
                        value: AppFormatters.cop(client.totalSpentCop),
                        sub: client.hasDebt
                            ? 'Debe ${AppFormatters.cop(client.pendingDebtCop)}'
                            : 'Al día',
                        icon: Icons.account_balance_wallet_rounded,
                        color: client.hasDebt
                            ? AppColors.statusDue
                            : AppColors.slate700,
                        isAlert: client.hasDebt,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bottom: Action Buttons
                Row(
                  children: [
                    if (client.phone.isNotEmpty) ...[
                      IconButton.outlined(
                        tooltip: 'Abrir WhatsApp',
                        onPressed: onWhatsAppTap,
                        icon: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: AppColors.whatsappDark,
                        ),
                        style: IconButton.styleFrom(
                          side: const BorderSide(color: AppColors.whatsapp),
                          backgroundColor: AppColors.successTint,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onHistoryTap,
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: const Text(
                          'Historial',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.slate700,
                          side: BorderSide(color: AppColors.slate200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onNewReservationTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reservar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    this.isAlert = false,
  });

  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.dangerTint : AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAlert
              ? AppColors.statusDue.withValues(alpha: 0.3)
              : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.slate500,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodyMd.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            sub,
            style: AppTypography.bodySm.copyWith(
              color: isAlert ? AppColors.statusDue : AppColors.slate500,
              fontSize: 10,
              fontWeight: isAlert ? FontWeight.w700 : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TierBadgeCompact extends StatelessWidget {
  const _TierBadgeCompact({required this.tier});

  final ClientTier tier;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (tier) {
      case ClientTier.vip:
        bg = AppColors.warningTint;
        fg = AppColors.warningInk;
      case ClientTier.frecuente:
        bg = AppColors.brandTealLight;
        fg = AppColors.brandTealDeep;
      case ClientTier.recurrente:
        bg = AppColors.infoTint;
        fg = AppColors.infoInk;
      case ClientTier.nuevo:
        bg = AppColors.slate100;
        fg = AppColors.slate700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tier.label,
        style: AppTypography.labelSm.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
