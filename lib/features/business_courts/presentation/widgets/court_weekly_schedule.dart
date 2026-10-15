import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/court_schedule.dart';
import '../../domain/entities/court_time.dart';
import 'court_time_picker.dart';

/// Horario de los 7 días: cada día se abre o cierra con el interruptor y
/// sus horas se eligen tocándolas. Un cierre menor que la apertura significa
/// que cierra al día siguiente (p. ej. 18:00 → 02:00).
class CourtWeeklySchedule extends StatelessWidget {
  const CourtWeeklySchedule({
    super.key,
    required this.schedules,
    required this.onChanged,
  });

  final List<DaySchedule> schedules;
  final ValueChanged<List<DaySchedule>> onChanged;

  void _replace(int index, DaySchedule day) =>
      onChanged([...schedules]..[index] = day);

  /// Copia el horario del primer día abierto a toda la semana.
  void _copyToAll() {
    final source = schedules.firstWhere((s) => s.isOpen);
    onChanged([
      for (final day in schedules)
        DaySchedule.open(day.day, open: source.open!, close: source.close!),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final anyOpen = schedules.any((s) => s.isOpen);
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, day) in schedules.indexed) ...[
            if (i > 0) const SizedBox(height: 6),
            _DayRow(schedule: day, onChanged: (value) => _replace(i, value)),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: anyOpen ? _copyToAll : null,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandTeal,
                textStyle: AppTypography.labelMd,
              ),
              icon: const Icon(Icons.copy_all_outlined, size: 18),
              label: const Text('Usar el primer horario en todos los días'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.schedule, required this.onChanged});

  final DaySchedule schedule;
  final ValueChanged<DaySchedule> onChanged;

  Future<void> _pick(BuildContext context, {required bool opening}) async {
    final current = opening ? schedule.open! : schedule.close!;
    final picked = await pickCourtTime(
      context,
      initial: current,
      helpText: opening
          ? 'Apertura · ${schedule.day.label}'
          : 'Cierre · ${schedule.day.label}',
    );
    if (picked == null) return;
    onChanged(
      DaySchedule.open(
        schedule.day,
        open: opening ? picked : schedule.open!,
        close: opening ? schedule.close! : picked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = schedule.day;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              day.label,
              style: AppTypography.headlineSm.copyWith(
                fontSize: 14,
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: schedule.isOpen
                ? Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      CourtTimeButton(
                        time: schedule.open!,
                        semanticLabel:
                            'Apertura ${day.label} ${schedule.open!.label}',
                        onPressed: () => _pick(context, opening: true),
                      ),
                      Text(
                        '–',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      CourtTimeButton(
                        time: schedule.close!,
                        semanticLabel:
                            'Cierre ${day.label} ${schedule.close!.label}',
                        onPressed: () => _pick(context, opening: false),
                      ),
                      if (schedule.closesNextDay)
                        Text(
                          '(día sig.)',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  )
                : Text(
                    'Cerrado',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
          ),
          Switch.adaptive(
            value: schedule.isOpen,
            activeTrackColor: AppColors.primary,
            onChanged: (open) => onChanged(
              open
                  ? DaySchedule.open(
                      day,
                      open: const CourtTime(6),
                      close: const CourtTime(22),
                    )
                  : DaySchedule.closed(day),
            ),
          ),
        ],
      ),
    );
  }
}
