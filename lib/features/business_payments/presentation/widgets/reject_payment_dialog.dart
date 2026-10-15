import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/payment.dart';

/// Confirma el rechazo de un pago y pide un motivo opcional.
/// Devuelve `null` si se cancela; si no, el motivo (puede ser vacío).
Future<String?> showRejectPaymentDialog(
  BuildContext context,
  Payment payment,
) => showDialog<String>(
  context: context,
  builder: (_) => _RejectPaymentDialog(payment: payment),
);

class _RejectPaymentDialog extends StatefulWidget {
  const _RejectPaymentDialog({required this.payment});

  final Payment payment;

  @override
  State<_RejectPaymentDialog> createState() => _RejectPaymentDialogState();
}

class _RejectPaymentDialogState extends State<_RejectPaymentDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    return AlertDialog(
      title: Text('¿Rechazar pago?', style: AppTypography.headlineSm),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${p.customerName} · ${AppFormatters.cop(p.amount)}',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            autofocus: true,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Motivo (opcional)',
              hintText: 'Ej.: el comprobante no coincide',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_reason.text),
          style: FilledButton.styleFrom(backgroundColor: AppColors.statusDue),
          child: const Text('Rechazar'),
        ),
      ],
    );
  }
}
