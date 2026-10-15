import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/reservation.dart';
import 'reservation_status_pill.dart';

/// Reserva en el listado general: fecha, cliente, cancha, horario, estado
/// y valores.
class ReservationListTile extends StatelessWidget {
  const ReservationListTile({
    super.key,
    required this.reservation,
    required this.onTap,
  });

  static const height = 124.0;

  final Reservation reservation;
  final VoidCallback onTap;

  static const _weekdays = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final cancelled = r.status == ReservationStatus.cancelled;
    final money = cancelled
        ? 'Cancelada'
        : r.isFullyPaid
        ? 'Pagada'
        : 'Saldo ${AppFormatters.cop(r.balance)}';
    return Semantics(
      button: true,
      label:
          '${r.customerName}, ${r.courtName}, '
          '${AppFormatters.shortDate(r.start)} '
          '${AppFormatters.timeRange(r.start, r.end)}, ${r.status.label}',
      excludeSemantics: true,
      child: Material(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: cancelled
                        ? AppColors.surfaceContainerHigh
                        : AppColors.brandTealLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _weekdays[r.start.weekday - 1],
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${r.start.day}',
                        style: AppTypography.headlineSm.copyWith(
                          color: cancelled
                              ? AppColors.onSurfaceVariant
                              : AppColors.brandTealDeep,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        _months[r.start.month - 1],
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLg.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                          decoration: cancelled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${r.courtName} · '
                        '${AppFormatters.timeRange(r.start, r.end)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ReservationStatusPill(status: r.status),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.cop(r.totalPrice),
                      style: AppTypography.labelLg.copyWith(
                        color: cancelled
                            ? AppColors.onSurfaceVariant
                            : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      money,
                      style: AppTypography.labelSm.copyWith(
                        color: r.isFullyPaid || cancelled
                            ? AppColors.onSurfaceVariant
                            : AppColors.statusDue,
                      ),
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
