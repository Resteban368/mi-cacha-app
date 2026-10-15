import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cop_input_formatter.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/court.dart';

/// Precio base por hora y duración del turno.
class CourtPricingCard extends StatelessWidget {
  const CourtPricingCard({
    super.key,
    required this.basePriceController,
    required this.slotDuration,
    required this.onSlotDurationChanged,
  });

  final TextEditingController basePriceController;
  final int slotDuration;
  final ValueChanged<int> onSlotDurationChanged;

  /// `30 min`, `1 h`, `1 h 30`, `3 h`…
  static String durationLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0
        ? '$hours h'
        : '$hours h ${rest.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            key: const Key('court-base-price'),
            controller: basePriceController,
            label: 'Precio base por hora',
            prefixIcon: Icons.attach_money,
            hintText: 'Ej: 80.000',
            keyboardType: TextInputType.number,
            inputFormatters: const [CopInputFormatter()],
          ),
          const SizedBox(height: 6),
          Text(
            'Se cobra en las horas que no cubre ninguna tarifa por franja.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'DURACIÓN DEL TURNO',
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
              for (final minutes in courtSlotDurations)
                ChoiceChip(
                  label: Text(durationLabel(minutes)),
                  selected: minutes == slotDuration,
                  onSelected: (_) => onSlotDurationChanged(minutes),
                  showCheckmark: false,
                  selectedColor: AppColors.brandTeal,
                  backgroundColor: AppColors.surfaceContainerLow,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelStyle: AppTypography.labelMd.copyWith(
                    color: minutes == slotDuration
                        ? AppColors.onPrimary
                        : AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
