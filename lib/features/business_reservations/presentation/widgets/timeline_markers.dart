import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/pulsing_dot.dart';

/// Separador de sección: "PASADAS ─────".
class TimelineSectionLabel extends StatelessWidget {
  const TimelineSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

/// Línea lima con la hora actual: "Ahora · 7:15 p. m.".
class NowMarker extends StatelessWidget {
  const NowMarker({super.key, required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            height: 2,
            width: double.infinity,
            child: ColoredBox(color: AppColors.accentLime),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.inverseSurface,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PulsingDot(),
                const SizedBox(width: 6),
                Text(
                  'Ahora · ${AppFormatters.time(now)}',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.accentLime,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
