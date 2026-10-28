import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../business_payments/domain/entities/payment.dart';
import '../../../business_payments/presentation/widgets/payment_styles.dart';
import '../../domain/entities/sale.dart';

/// Una venta: sus productos, hora, total y, si se anuló, el motivo.
/// [onVoid] muestra el botón para anularla.
class SaleTile extends StatelessWidget {
  const SaleTile({super.key, required this.sale, this.title, this.onVoid});

  final Sale sale;

  /// Línea superior (p. ej. cliente o "Venta suelta"); por defecto la hora.
  final String? title;
  final VoidCallback? onVoid;

  @override
  Widget build(BuildContext context) {
    final voided = sale.isVoided;
    final method = switch (sale.paymentMethod) {
      final code? => PaymentMethod.fromApi(code),
      null => null,
    };
    final meta = [
      if (title != null) AppFormatters.time(sale.createdAt),
      if (method != null) method.label,
      if (voided)
        'Anulada${sale.voidReason == null ? '' : ': ${sale.voidReason}'}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: voided ? AppColors.surfaceContainerLow : AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? AppFormatters.time(sale.createdAt),
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sale.itemsLabel,
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: voided ? AppColors.slate400 : AppColors.onSurface,
                    decoration: voided ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    style: AppTypography.bodySm.copyWith(
                      color: voided ? AppColors.statusDue : AppColors.slate500,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppFormatters.cop(sale.total),
            style: AppTypography.bodyMd.copyWith(
              fontWeight: FontWeight.w800,
              color: voided ? AppColors.slate400 : AppColors.onSurface,
              decoration: voided ? TextDecoration.lineThrough : null,
            ),
          ),
          if (onVoid != null && !voided)
            IconButton(
              key: Key('void-${sale.id}'),
              tooltip: 'Anular',
              onPressed: onVoid,
              icon: Icon(
                Icons.remove_shopping_cart_outlined,
                size: 18,
                color: AppColors.slate500,
              ),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// Pide el motivo para anular una venta; `null` si no se confirma.
Future<String?> showVoidSaleDialog(BuildContext context) =>
    showDialog<String>(context: context, builder: (_) => const _VoidDialog());

class _VoidDialog extends StatefulWidget {
  const _VoidDialog();

  @override
  State<_VoidDialog> createState() => _VoidDialogState();
}

class _VoidDialogState extends State<_VoidDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('¿Anular esta venta?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Deja de sumar al total y queda registrada como anulada. Si ya '
            'la pagaron, devuelve el dinero al cliente.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('void-reason'),
            controller: _reason,
            autofocus: true,
            maxLength: 300,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              hintText: 'Ej. Se registró dos veces',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(
          key: const Key('void-confirm'),
          onPressed: _reason.text.trim().length < 3
              ? null
              : () => Navigator.of(context).pop(_reason.text.trim()),
          style: FilledButton.styleFrom(backgroundColor: AppColors.statusDue),
          child: const Text('Anular'),
        ),
      ],
    );
  }
}
