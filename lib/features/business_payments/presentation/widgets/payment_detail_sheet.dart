import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/payment.dart';
import 'payment_styles.dart';

/// Detalle completo de un pago (se abre al tocar su tarjeta).
Future<void> showPaymentDetailSheet(BuildContext context, Payment payment) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => _PaymentDetail(payment: payment),
  );
}

class _PaymentDetail extends StatelessWidget {
  const _PaymentDetail({required this.payment});

  final Payment payment;

  static String _dateTime(DateTime d) =>
      '${AppFormatters.mediumDate(d)} · ${AppFormatters.time(d)}';

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final rows = <(String, String)>[
      ('Cliente', p.customerName),
      ('Concepto', p.concept.label),
      ('Medio de pago', p.method.label),
      if (p.reference != null) ('Referencia', p.reference!),
      if (p.courtName != null) ('Cancha', p.courtName!),
      if (p.reservationStart != null)
        ('Reserva', _dateTime(p.reservationStart!)),
      ('Recibido', _dateTime(p.receivedAt)),
      ('Registrado por', p.registeredByBusiness ? 'El negocio' : 'El jugador'),
      ('Estado', p.status.label),
      if (p.note != null && p.note!.isNotEmpty) ('Nota', p.note!),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: p.method.tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(p.method.icon, color: p.method.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppFormatters.cop(p.amount),
                    style: AppTypography.headlineMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        label,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: AppTypography.labelLg.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
