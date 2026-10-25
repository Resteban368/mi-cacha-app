import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/pulsing_dot.dart';

/// "Hoy" + selector de fecha, navegación día por día y acceso al calendario.
class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.day,
    required this.isToday,
    required this.onOpenCalendar,
    this.onPreviousDay,
    this.onNextDay,
    this.onJumpToday,
  });

  final DateTime day;
  final bool isToday;
  final VoidCallback onOpenCalendar;
  final VoidCallback? onPreviousDay;
  final VoidCallback? onNextDay;
  final VoidCallback? onJumpToday;

  @override
  Widget build(BuildContext context) {
    final date = AppFormatters.longDate(day);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isVeryCompact = constraints.maxWidth < 360;
        final isCompact = constraints.maxWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Stepper de navegación: [Hoy] [<] [>]
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: isToday
                            ? AppColors.surfaceContainerLowest
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        elevation: isToday ? 1 : 0,
                        shadowColor: Colors.black12,
                        child: InkWell(
                          onTap: onJumpToday,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVeryCompact ? 6 : 10,
                              vertical: 6,
                            ),
                            child: Text(
                              'Hoy',
                              style: AppTypography.labelSm.copyWith(
                                color: isToday
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                        onPressed: onPreviousDay,
                        tooltip: 'Día anterior',
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints.tightFor(
                          width: isVeryCompact ? 26 : 30,
                          height: 30,
                        ),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      IconButton(
                        onPressed: onNextDay,
                        tooltip: 'Día siguiente',
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints.tightFor(
                          width: isVeryCompact ? 26 : 30,
                          height: 30,
                        ),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isVeryCompact ? 6 : 10),
                // Título fecha principal
                Expanded(
                  child: InkWell(
                    onTap: onOpenCalendar,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 2,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  date,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.headlineSm.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w800,
                                    fontSize: isCompact ? 15 : 18,
                                  ),
                                ),
                              ),
                              if (isToday) ...[
                                const SizedBox(width: 4),
                                PulsingDot(
                                  color: AppColors.statusPaid,
                                  size: 7,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Turno operativo de 6:00 a. m. a 11:30 p. m.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Botón calendario
                Material(
                  color: AppColors.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 1,
                  shadowColor: Colors.black12,
                  child: IconButton(
                    onPressed: onOpenCalendar,
                    tooltip: 'Abrir calendario completo',
                    iconSize: 20,
                    color: AppColors.primary,
                    constraints: const BoxConstraints.tightFor(
                      width: 38,
                      height: 38,
                    ),
                    icon: const Icon(Icons.calendar_month_outlined),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
