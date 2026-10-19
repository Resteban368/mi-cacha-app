import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/catalogs/domain/entities/catalog_payment_method.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cop_input_formatter.dart';
import '../../../../core/utils/formatters.dart';
import 'reservation_section_card.dart';

/// Valor de la reserva (subtotal estimado, descuento y total) y el pago
/// opcional que se registra al reservar.
class CreateReservationPaymentCard extends StatelessWidget {
  const CreateReservationPaymentCard({
    super.key,
    required this.subtotal,
    this.lowestSubtotal,
    this.durationLabel,
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

  /// Con "Cualquier cancha", lo mínimo que puede valer (la API puede
  /// asignar una cancha más barata): limita el descuento y el pago.
  final int? lowestSubtotal;

  /// Duración elegida (p. ej. "1 h") para la fila del subtotal.
  final String? durationLabel;
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

  int? get _lowest => lowestSubtotal ?? subtotal;

  bool get _mayVary => _lowest != null && _lowest != subtotal;

  /// Lo máximo que se puede registrar como pago.
  int? get _payLimit {
    final value = _lowest;
    return value == null ? null : (value - _discount).clamp(0, value);
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final limit = _payLimit;
    final paid = registerPayment
        ? CopInputFormatter.parse(amountController.text)
        : 0;
    return ReservationSectionCard(
      compact: true,
      icon: Icons.monetization_on_outlined,
      title: 'Valor y liquidación',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReservationAmountRow(
            label: durationLabel == null
                ? 'Subtotal del turno'
                : 'Subtotal del turno ($durationLabel)',
            value: subtotal == null ? '—' : AppFormatters.cop(subtotal!),
          ),
          const SizedBox(height: 6),
          _InlineField(
            label: 'Descuento (opcional)',
            field: _MoneyField(
              key: const Key('reservation-discount'),
              controller: discountController,
              icon: Icons.discount_outlined,
              hint: '0',
              validator: (_) => _lowest != null && _discount > _lowest!
                  ? 'No puede superar el subtotal.'
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Total estimado',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Tooltip(
                      message:
                          'El valor final lo calcula el sistema con las '
                          'tarifas vigentes.',
                      child: Icon(
                        Icons.info_outline,
                        size: 15,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                total == null ? '—' : AppFormatters.cop(total),
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          if (_mayVary)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Puede ser desde ${AppFormatters.cop(limit!)} según la cancha '
                'que se asigne.',
                key: const Key('price-may-vary'),
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: AppColors.slate100),
          SwitchListTile.adaptive(
            key: const Key('register-payment'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: registerPayment,
            onChanged: onRegisterPaymentChanged,
            activeTrackColor: AppColors.brandTeal,
            title: Text(
              'Registrar abono / anticipo',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.slate900,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              'Recibido al crear la reserva',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.slate500,
                fontSize: 11,
              ),
            ),
          ),
          if (registerPayment)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _paymentFields(total, limit, paid),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _paymentFields(int? total, int? limit, int paid) => [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MoneyField(
            key: const Key('payment-amount'),
            controller: amountController,
            icon: Icons.attach_money,
            hint: 'Monto recibido',
            validator: (_) {
              final amount = CopInputFormatter.parse(amountController.text);
              if (amount <= 0) return 'Ingresa el monto.';
              if (limit != null && amount > limit) {
                return _mayVary
                    ? 'Máximo ${AppFormatters.cop(limit)} (el valor '
                          'más bajo posible).'
                    : 'No puede superar el total.';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 40,
          child: OutlinedButton(
            key: const Key('pay-total'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: limit == null || limit == 0
                ? null
                : () => amountController.text = CopInputFormatter.format(limit),
            child: const Text('Pago total'),
          ),
        ),
      ],
    ),
    const SizedBox(height: 8),
    Text(
      'MEDIO DE PAGO RECIBIDO',
      style: AppTypography.labelSm.copyWith(
        color: AppColors.slate500,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        fontSize: 10,
      ),
    ),
    const SizedBox(height: 6),
    Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final method in methods)
          _MethodButton(
            label: method.name,
            selected: method.code == selectedMethod?.code,
            onTap: () => onMethodChanged(method),
          ),
      ],
    ),
    if (selectedMethod?.requiresReference ?? false) ...[
      const SizedBox(height: 8),
      _MoneyField(
        key: const Key('payment-reference'),
        controller: referenceController,
        icon: Icons.tag,
        hint: 'Referencia de ${selectedMethod!.name} (opcional)',
        numeric: false,
        validator: (_) => null,
      ),
    ],
    if (total != null) ...[
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: paid >= total
              ? AppColors.brandTealLight
              : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                paid >= total ? 'Queda pagada' : 'Saldo pendiente en taquilla',
                style: AppTypography.bodySm.copyWith(
                  color: paid >= total
                      ? AppColors.brandTealDeep
                      : const Color(0xFFB45309),
                  fontSize: 11,
                ),
              ),
            ),
            Text(
              AppFormatters.cop((total - paid).clamp(0, total)),
              style: AppTypography.labelMd.copyWith(
                color: paid >= total
                    ? AppColors.brandTealDeep
                    : const Color(0xFFB45309),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ],
  ];
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? AppColors.brandTeal
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minWidth: 70),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.brandTeal : AppColors.slate200,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.labelSm.copyWith(
                color: selected ? AppColors.onPrimary : AppColors.slate700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta a la izquierda y campo a la derecha, en una sola fila.
class _InlineField extends StatelessWidget {
  const _InlineField({required this.label, required this.field});

  final String label;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 160, child: field),
      ],
    );
  }
}

/// Campo compacto (40 px de alto) para montos o la referencia del pago.
class _MoneyField extends StatelessWidget {
  const _MoneyField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    required this.validator,
    this.numeric = true,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final FormFieldValidator<String> validator;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );
    return TextFormField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: numeric
          ? const [CopInputFormatter()]
          : [LengthLimitingTextInputFormatter(60)],
      validator: validator,
      style: AppTypography.bodyMd.copyWith(color: AppColors.slate900),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.slate400),
        prefixIcon: Icon(icon, size: 16, color: AppColors.slate400),
        prefixIconConstraints: const BoxConstraints(minWidth: 34),
        suffixText: numeric ? 'COP' : null,
        suffixStyle: AppTypography.labelSm.copyWith(
          color: AppColors.slate400,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 11,
        ),
        enabledBorder: border(AppColors.slate200),
        focusedBorder: border(AppColors.brandTeal),
        errorBorder: border(AppColors.statusDue),
        focusedErrorBorder: border(AppColors.statusDue),
        errorMaxLines: 2,
      ),
    );
  }
}
