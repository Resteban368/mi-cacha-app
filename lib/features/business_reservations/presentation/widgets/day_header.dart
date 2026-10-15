import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';

/// "Hoy" + fecha larga y acceso al calendario.
class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.day,
    required this.isToday,
    required this.onOpenCalendar,
  });

  final DateTime day;
  final bool isToday;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final date = AppFormatters.longDate(day);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Hoy' : date.split(',').first,
                  style: AppTypography.displayLgMobile.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        date,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: 4),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.surfaceContainerHigh,
            shape: const CircleBorder(),
            elevation: 1,
            shadowColor: Colors.black26,
            child: IconButton(
              onPressed: onOpenCalendar,
              tooltip: 'Abrir calendario completo',
              iconSize: 24,
              color: AppColors.primary,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
