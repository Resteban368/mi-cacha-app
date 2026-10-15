import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/catalogs/domain/entities/catalog_payment_method.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cop_input_formatter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'reservation_section_card.dart';

/// Valor de la reserva (subtotal estimado, descuento y total) y el pago
/// opcional que se registra al reservar.
class CreateReservationPaymentCard extends StatelessWidget {
  const CreateReservationPaymentCard({
    super.key,
    required this.subtotal,
    required this.discountController,
    required this.registerPayment,
    required this.onRegisterPaymentChanged,
    required this.amountController,
    required this.methods,
    required this.selectedMethod,
    required this.onMethodChanged,
    required this.referenceController,
  });

  /// Suma de los turnos elegidos; `null` si aún no hay turno.
  final int? subtotal;
  final TextEditingController discountController;
  final bool registerPayment;
  final ValueChanged<bool> onRegisterPaymentChanged;
  final TextEditingController amountController;
  final List<CatalogPaymentMethod> methods;
  final CatalogPaymentMethod? selectedMethod;
  final ValueChanged<CatalogPaymentMethod> onMethodChanged;
  final TextEditingController referenceController;

  int get _discount => CopInputFormatter.parse(discountController.text);

  int? get _total {
    final value = subtotal;
    return value == null ? null : (value - _discount).clamp(0, value);
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final paid = registerPayment
        ? CopInputFormatter.parse(amountController.text)
        : 0;
    return ReservationSectionCard(
      icon: Icons.payments_outlined,
      title: 'Valor y pago',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReservationAmountRow(
            label: 'Subtotal (según tarifas)',
            value: subtotal == null ? '—' : AppFormatters.cop(subtotal!),
          ),
          const SizedBox(height: 10),
          AppTextField(
            key: const Key('reservation-discount'),
            controller: discountController,
            label: 'Descuento (opcional)',
            prefixIcon: Icons.discount_outlined,
            hintText: '0',
            keyboardType: TextInputType.number,
            inputFormatters: const [CopInputFormatter()],
            validator: (_) => subtotal != null && _discount > subtotal!
                ? 'No puede superar el subtotal.'
                : null,
          ),
          const SizedBox(height: 10),
          ReservationAmountRow(
            label: 'Total estimado',
            value: total == null ? '—' : AppFormatters.cop(total),
            emphasis: true,
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          SwitchListTile.adaptive(
            key: const Key('register-payment'),
            contentPadding: EdgeInsets.zero,
            value: registerPayment,
            onChanged: onRegisterPaymentChanged,
            activeTrackColor: AppColors.primary,
            title: Text(
              'Registrar pago',
              style: AppTypography.labelLg.copyWith(color: AppColors.onSurface),
            ),
            subtitle: Text(
              'Anticipo o pago total recibido al reservar.',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          if (registerPayment) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    key: const Key('payment-amount'),
                    controller: amountController,
                    label: 'Monto recibido',
                    prefixIcon: Icons.attach_money,
                    hintText: 'Ej. 50.000',
                    keyboardType: TextInputType.number,
                    inputFormatters: const [CopInputFormatter()],
                    validator: (_) {
                      final amount = CopInputFormatter.parse(
                        amountController.text,
                      );
                      if (amount <= 0) return 'Ingresa el monto.';
                      if (total != null && amount > total) {
                        return 'No puede superar el total.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: OutlinedButton(
                    key: const Key('pay-total'),
                    onPressed: total == null || total == 0
                        ? null
                        : () => amountController.text =
                              CopInputFormatter.format(total),
                    child: const Text('Pago total'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'MÉTODO DE PAGO',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final method in methods)
                  ChoiceChip(
                    label: Text(method.name),
                    selected: method.code == selectedMethod?.code,
                    onSelected: (_) => onMethodChanged(method),
                    showCheckmark: false,
                    selectedColor: AppColors.brandTeal,
                    labelStyle: AppTypography.labelMd.copyWith(
                      color: method.code == selectedMethod?.code
                          ? AppColors.onPrimary
                          : AppColors.onSurface,
                    ),
                  ),
              ],
            ),
            if (selectedMethod?.requiresReference ?? false) ...[
              const SizedBox(height: 12),
              AppTextField(
                key: const Key('payment-reference'),
                controller: referenceController,
                label: 'Referencia de ${selectedMethod!.name}',
                prefixIcon: Icons.tag,
                hintText: 'Número o código del comprobante',
                inputFormatters: [LengthLimitingTextInputFormatter(60)],
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Este método exige la referencia.'
                    : null,
              ),
            ],
            if (total != null) ...[
              const SizedBox(height: 12),
              ReservationAmountRow(
                label: paid >= total ? 'Queda pagada' : 'Saldo pendiente',
                value: AppFormatters.cop((total - paid).clamp(0, total)),
                valueColor: paid >= total
                    ? AppColors.brandTeal
                    : AppColors.onSurface,
              ),
            ],
          ],
          const SizedBox(height: 6),
          Text(
            'El valor final lo calcula el sistema con las tarifas vigentes.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
