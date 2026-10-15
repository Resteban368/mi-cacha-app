import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/payment.dart';
import 'payment_styles.dart';

/// Selector segmentado Por validar / Aprobados / Rechazados con conteos.
class PaymentsTabs extends StatelessWidget {
  const PaymentsTabs({
    super.key,
    required this.selected,
    required this.countFor,
    required this.onChanged,
  });

  final PaymentStatus selected;
  final int Function(PaymentStatus) countFor;
  final ValueChanged<PaymentStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final status in PaymentStatus.tabs)
            Expanded(
              child: _Segment(
                label: status.tabLabel,
                count: countFor(status),
                selected: status == selected,
                highlight: status == PaymentStatus.pending,
                onTap: () => onChanged(status),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.count,
    required this.selected,
    required this.highlight,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;

  /// Resalta el conteo (pendientes) en ámbar cuando hay elementos.
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badgeBg = highlight && count > 0
        ? AppColors.statusDeposit
        : (selected
              ? AppColors.brandTealLight
              : AppColors.surfaceContainerHigh);
    final badgeFg = highlight && count > 0
        ? AppColors.onPrimary
        : (selected ? AppColors.brandTeal : AppColors.onSurfaceVariant);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.surfaceContainerLowest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd.copyWith(
                        color: selected
                            ? AppColors.onSurface
                            : AppColors.onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.labelSm.copyWith(
                        color: badgeFg,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
