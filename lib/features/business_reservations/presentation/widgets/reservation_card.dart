import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/reservation.dart';
import 'reservation_card_parts.dart';

/// Tarjeta estándar (reservas pasadas y próximas).
class ReservationCard extends StatelessWidget {
  const ReservationCard({
    super.key,
    required this.reservation,
    required this.timing,
  });

  final Reservation reservation;
  final ReservationTiming timing;

  bool get _isFinished =>
      reservation.status == ReservationStatus.completed ||
      timing == ReservationTiming.past;

  Color get _stripeColor {
    if (reservation.status == ReservationStatus.noShow) {
      return AppColors.statusDue;
    }
    if (!reservation.isFullyPaid) return AppColors.statusDeposit;
    return _isFinished ? AppColors.statusPaid : AppColors.brandTeal;
  }

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final time =
        '${AppFormatters.timeRange(r.start, r.end)} '
        '(${AppFormatters.duration(r.duration)})';

    return StripedCard(
      stripeColor: _stripeColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CourtChip(reservation: r),
                        Text(
                          time,
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: r.customerName,
                        children: [
                          if (r.customerDetail != null)
                            TextSpan(
                              text: ' · ${r.customerDetail}',
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    _ContactLine(reservation: r),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ContactActions(reservation: r),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(child: _PaymentSummary(card: this)),
                const SizedBox(width: 8),
                _trailing(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trailing() {
    if (reservation.status == ReservationStatus.noShow) {
      return const StatusPill(
        label: 'No asistió',
        icon: Icons.cancel_outlined,
        background: AppColors.errorContainer,
        foreground: AppColors.onErrorContainer,
      );
    }
    if (_isFinished) {
      return const StatusPill(
        label: 'Completada',
        icon: Icons.check_circle_outline,
        background: AppColors.brandTealLight,
        foreground: AppColors.brandTeal,
      );
    }
    if (reservation.isFullyPaid) {
      return const StatusPill(
        label: 'Confirmada',
        icon: Icons.verified_outlined,
        background: AppColors.surfaceContainerHigh,
        foreground: AppColors.primary,
      );
    }
    return Material(
      color: AppColors.secondaryFixed,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        // TODO: flujo de cobro en taquilla.
        onTap: () {},
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            'Cobrar en taquilla',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSecondaryFixedVariant,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final base = AppTypography.bodySm.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(
            text: r.contactNote == null
                ? r.phone
                : '${r.phone} (${r.contactNote})',
          ),
          if (r.tag != null) ...[
            const TextSpan(
              text: ' · ',
              style: TextStyle(color: AppColors.outlineVariant),
            ),
            TextSpan(
              text: r.tag,
              style: base.copyWith(color: AppColors.primary),
            ),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.card});

  final ReservationCard card;

  @override
  Widget build(BuildContext context) {
    final r = card.reservation;
    final label = AppTypography.labelSm;

    if (r.isFullyPaid) {
      final amount = card._isFinished
          ? '${AppFormatters.cop(r.totalPrice)} COP'
          : 'Total: ${AppFormatters.cop(r.totalPrice)} COP';
      return Row(
        children: [
          Flexible(
            child: Text(
              amount,
              overflow: TextOverflow.ellipsis,
              style: label.copyWith(color: AppColors.statusPaid),
            ),
          ),
          const SizedBox(width: 6),
          const PaidTag(),
        ],
      );
    }

    final balanceColor = r.status == ReservationStatus.noShow
        ? AppColors.statusDue
        : AppColors.statusDeposit;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Anticipo: ${AppFormatters.cop(r.amountPaid)}',
            style: label.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(
            text: ' · ',
            style: TextStyle(color: AppColors.outlineVariant),
          ),
          TextSpan(
            text:
                'Saldo: ${AppFormatters.cop(r.balance)}'
                '${card._isFinished ? '' : ' COP'}',
            style: label.copyWith(color: balanceColor),
          ),
        ],
      ),
      style: label,
    );
  }
}
