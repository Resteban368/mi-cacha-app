import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/payment.dart';
import 'payment_styles.dart';

/// Tarjeta de un pago. Si está pendiente muestra Rechazar / Aprobar.
class PaymentCard extends StatelessWidget {
  const PaymentCard({
    super.key,
    required this.payment,
    required this.now,
    this.processing = false,
    this.onApprove,
    this.onReject,
    this.onTap,
  });

  final Payment payment;
  final DateTime now;
  final bool processing;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final details = [
      p.concept.label,
      if (p.courtName != null) p.courtName!,
      if (p.reservationStart != null) reservationWhen(p.reservationStart!, now),
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandTeal.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: p.method.tint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        p.method.icon,
                        size: 22,
                        color: p.method.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headlineSm.copyWith(
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            details,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppFormatters.cop(p.amount),
                          style: AppTypography.headlineMd.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: p.status == PaymentStatus.rejected
                                ? AppColors.outline
                                : AppColors.onSurface,
                            decoration: p.status == PaymentStatus.rejected
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          AppFormatters.relative(p.receivedAt, now),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.outline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Tag(
                      label: p.method.label,
                      background: p.method.tint,
                      foreground: p.method.color,
                    ),
                    if (p.reference != null)
                      _Tag(
                        label: 'Ref. ${p.reference}',
                        background: AppColors.surfaceContainer,
                        foreground: AppColors.onSurfaceVariant,
                      ),
                    if (p.registeredByBusiness)
                      _Tag(
                        label: 'Registrado por ti',
                        background: AppColors.surfaceContainer,
                        foreground: AppColors.onSurfaceVariant,
                      ),
                    _StatusPill(status: p.status),
                  ],
                ),
                if (p.note != null && p.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    p.note!,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (p.status == PaymentStatus.rejected &&
                    p.rejectionReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dangerTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppColors.dangerInk,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p.rejectionReason!,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.dangerInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (p.status == PaymentStatus.pending) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: processing ? null : onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.statusDue,
                            side: BorderSide(
                              color: AppColors.statusDue.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: AppTypography.labelLg,
                          ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Rechazar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: processing ? null : onApprove,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandTeal,
                            disabledBackgroundColor: AppColors.brandTeal
                                .withValues(alpha: 0.6),
                            foregroundColor: AppColors.onPrimary,
                            disabledForegroundColor: AppColors.onPrimary,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: AppTypography.labelLg,
                          ),
                          icon: processing
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Aprobar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(color: foreground),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, bg, fg) = switch (status) {
      PaymentStatus.pending => (
        'Por validar',
        Icons.hourglass_top_rounded,
        AppColors.warningTint,
        AppColors.warningInk,
      ),
      PaymentStatus.approved => (
        'Aprobado',
        Icons.check_circle_outline,
        AppColors.brandTealLight,
        AppColors.brandTeal,
      ),
      PaymentStatus.rejected => (
        'Rechazado',
        Icons.cancel_outlined,
        AppColors.dangerTint,
        AppColors.dangerInk,
      ),
      PaymentStatus.refunded => (
        'Devuelto',
        Icons.undo_rounded,
        AppColors.surfaceContainerHigh,
        AppColors.onSurfaceVariant,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: fg, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
