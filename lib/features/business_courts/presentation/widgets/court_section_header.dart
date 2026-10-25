import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Encabezado numerado para cada sección del formulario de creación de cancha.
class CourtSectionHeader extends StatelessWidget {
  const CourtSectionHeader({
    super.key,
    required this.number,
    required this.title,
    this.trailing,
  });

  final int number;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.onSurface,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
