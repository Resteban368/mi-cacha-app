import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/reservation.dart';
import 'reservation_section_card.dart';

enum ReservationSummaryAction { viewAgenda, createAnother }

/// Resumen tras crear la reserva: total, pagado, saldo y estado. Con
/// [courtAssigned] (la API eligió la cancha) se destaca en cuál quedó.
Future<ReservationSummaryAction?> showReservationSummary(
  BuildContext context,
  Reservation reservation, {
  bool courtAssigned = false,
}) => showDialog<ReservationSummaryAction>(
  context: context,
  barrierDismissible: false,
  builder: (context) => AlertDialog(
    icon: const Icon(Icons.check_circle, color: AppColors.brandTeal, size: 40),
    title: const Text('Reserva confirmada'),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (courtAssigned) ...[
            Container(
              key: const Key('assigned-court'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.brandTealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Reserva creada en ${reservation.courtsLabel}',
                textAlign: TextAlign.center,
                style: AppTypography.labelLg.copyWith(
                  color: AppColors.brandTealDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            '${reservation.courtsLabel} · '
            '${AppFormatters.shortDate(reservation.start)} · '
            '${AppFormatters.timeRange(reservation.start, reservation.end)}',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reservation.customerName,
            textAlign: TextAlign.center,
            style: AppTypography.labelLg.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 12),
          if (reservation.discount > 0) ...[
            ReservationAmountRow(
              label: 'Subtotal',
              value: AppFormatters.cop(reservation.subtotal),
            ),
            ReservationAmountRow(
              label: 'Descuento',
              value: '−${AppFormatters.cop(reservation.discount)}',
            ),
          ],
          ReservationAmountRow(
            label: 'Total',
            value: AppFormatters.cop(reservation.displayTotal),
            emphasis: true,
          ),
          ReservationAmountRow(
            label: 'Pagado',
            value: AppFormatters.cop(reservation.displayPaid),
          ),
          ReservationAmountRow(
            label: 'Saldo',
            value: AppFormatters.cop(reservation.displayBalance),
            valueColor: reservation.isFullyPaid ? AppColors.brandTeal : null,
          ),
          ReservationAmountRow(
            label: 'Estado',
            value: reservation.status.label,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () =>
            Navigator.of(context).pop(ReservationSummaryAction.createAnother),
        child: const Text('Nueva reserva'),
      ),
      FilledButton(
        onPressed: () =>
            Navigator.of(context).pop(ReservationSummaryAction.viewAgenda),
        child: const Text('Ver en la agenda'),
      ),
    ],
  ),
);
