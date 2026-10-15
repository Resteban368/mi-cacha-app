import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/pulsing_dot.dart';
import '../../domain/entities/reservation.dart';
import 'reservation_card_parts.dart';

/// Tarjeta destacada de la reserva que se está jugando ahora.
class LiveReservationCard extends StatelessWidget {
  const LiveReservationCard({super.key, required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    return StripedCard(
      stripeColor: AppColors.accentLime,
      stripeWidth: 8,
      radius: 16,
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wrap: en pantallas angostas el horario pasa a la siguiente línea.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentLime,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PulsingDot(color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'EN JUEGO',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.inverseSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CourtChip(reservation: r),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.update, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    AppFormatters.timeRange(r.start, r.end),
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            r.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headlineMd.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (r.isRecurring) ...[
                          const SizedBox(width: 6),
                          const Tooltip(
                            message: 'Reserva semanal recurrente',
                            child: Icon(
                              Icons.repeat,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        children: [
                          TextSpan(text: r.phone),
                          if (r.tag != null) ...[
                            const TextSpan(
                              text: ' · ',
                              style: TextStyle(color: AppColors.outlineVariant),
                            ),
                            TextSpan(
                              text: r.tag,
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ContactActions(
                reservation: r,
                size: 36,
                callBackground: AppColors.surfaceContainerHigh,
                whatsappAlpha: 0.2,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceTealSubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: r.isFullyPaid
                      ? Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Total: ${AppFormatters.cop(r.totalPrice)} COP',
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.statusPaid,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const PaidTag(),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anticipo: ${AppFormatters.cop(r.amountPaid)}',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Saldo: ${AppFormatters.cop(r.balance)} COP',
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.statusDeposit,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
                if (!r.isFullyPaid) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    // TODO: flujo de cobro del saldo.
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentLime,
                      foregroundColor: AppColors.inverseSurface,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: AppTypography.labelMd.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.point_of_sale, size: 16),
                    label: const Text('Cobrar saldo'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
