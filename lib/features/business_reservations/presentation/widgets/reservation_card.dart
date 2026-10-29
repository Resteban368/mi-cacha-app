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
    this.isSelected = false,
    this.onQuickCollect,
  });

  final Reservation reservation;
  final ReservationTiming timing;
  final bool isSelected;
  final VoidCallback? onQuickCollect;

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
      isSelected: isSelected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isSelected)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandTeal,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Seleccionada en Taquilla',
                  style: AppTypography.labelSm.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

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
                        if (r.group != null && r.group!.courts.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.brandTealLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.brandTeal.withValues(
                                  alpha: 0.35,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.layers_rounded,
                                  size: 13,
                                  color: AppColors.brandTealDeep,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Múltiple (${r.group!.courts.length})',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.brandTealDeep,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                _PaymentSummary(card: this),
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
      return StatusPill(
        label: 'No asistió',
        icon: Icons.cancel_outlined,
        background: AppColors.errorContainer,
        foreground: AppColors.onErrorContainer,
      );
    }
    if (_isFinished) {
      return StatusPill(
        label: 'Completada',
        icon: Icons.check_circle_outline,
        background: AppColors.brandTealLight,
        foreground: AppColors.brandTeal,
      );
    }
    if (reservation.isFullyPaid) {
      return StatusPill(
        label: 'Confirmada',
        icon: Icons.verified_outlined,
        background: AppColors.surfaceContainerHigh,
        foreground: AppColors.primary,
      );
    }
    return Material(
      color: AppColors.secondaryFixed,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onQuickCollect,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.point_of_sale_rounded,
                size: 13,
                color: AppColors.onSecondaryFixedVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Cobrar en taquilla',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSecondaryFixedVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
            TextSpan(
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
          ? '${AppFormatters.cop(r.displayTotal)} COP'
          : 'Total: ${AppFormatters.cop(r.displayTotal)} COP';
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              amount,
              maxLines: 1,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Anticipo: ${AppFormatters.cop(r.displayPaid)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: label.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Saldo: ${AppFormatters.cop(r.displayBalance)}'
          '${card._isFinished ? '' : ' COP'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: label.copyWith(
            color: balanceColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
