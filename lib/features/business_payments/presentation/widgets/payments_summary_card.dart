import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../bloc/payments/payments_bloc.dart';
import 'payment_styles.dart';

/// Totales de los pagos que se ven: total, por medio de pago y cuánto fue
/// para canchas, consumos de reservas y ventas de mostrador.
class PaymentsSummaryCard extends StatelessWidget {
  const PaymentsSummaryCard({super.key, required this.summary});

  final PaymentsSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final concepts = [
      (
        Icons.sports_soccer_rounded,
        'Canchas',
        s.courts,
        AppColors.brandTeal,
        const Key('summary-courts'),
      ),
      (
        Icons.local_drink_rounded,
        'Consumos en reservas',
        s.consumptions,
        AppColors.amber500,
        const Key('summary-consumptions'),
      ),
      (
        Icons.storefront_rounded,
        'Ventas de mostrador',
        s.walkIn,
        AppColors.emerald600,
        const Key('summary-walk-in'),
      ),
    ];
    final total = Column(
      key: const Key('summary-total'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOTAL',
          style: AppTypography.labelSm.copyWith(
            color: AppColors.slate500,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          AppFormatters.cop(s.total),
          style: AppTypography.headlineMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          s.count == 1 ? '1 pago' : '${s.count} pagos',
          style: AppTypography.bodySm.copyWith(color: AppColors.slate500),
        ),
      ],
    );
    final byConcept = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title('POR CONCEPTO'),
        for (final (icon, label, amount, color, key) in concepts)
          _Line(
            key: key,
            leading: Icon(icon, size: 16, color: color),
            label: label,
            amount: amount,
          ),
      ],
    );
    final byMethod = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title('POR MEDIO DE PAGO'),
        if (s.byMethod.isEmpty)
          Text(
            'Sin pagos',
            style: AppTypography.bodySm.copyWith(color: AppColors.slate500),
          ),
        for (final entry in s.byMethod)
          _Line(
            key: Key('summary-method-${entry.key.name}'),
            leading: Icon(entry.key.icon, size: 16, color: entry.key.color),
            label: entry.key.label,
            amount: entry.value,
          ),
      ],
    );
    return Container(
      key: const Key('payments-summary'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant, width: 1.5),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 640) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                total,
                const Divider(height: 24),
                byConcept,
                const Divider(height: 24),
                byMethod,
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 180, child: total),
                const VerticalDivider(width: 32),
                Expanded(child: byConcept),
                const VerticalDivider(width: 32),
                Expanded(child: byMethod),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: AppTypography.labelSm.copyWith(
        color: AppColors.slate500,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line({
    super.key,
    required this.leading,
    required this.label,
    required this.amount,
  });

  final Widget leading;
  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        leading,
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm.copyWith(color: AppColors.slate700),
          ),
        ),
        Text(
          AppFormatters.cop(amount),
          style: AppTypography.bodySm.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
