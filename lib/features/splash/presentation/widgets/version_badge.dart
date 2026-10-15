import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class VersionBadge extends StatelessWidget {
  const VersionBadge({super.key, required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_open, size: 14, color: AppColors.onPrimary),
          const SizedBox(width: 8),
          Text(
            'VERSIÓN $version',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onPrimary,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
