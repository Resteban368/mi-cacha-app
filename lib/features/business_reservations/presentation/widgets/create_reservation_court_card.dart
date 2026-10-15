import 'package:flutter/material.dart';

import '../../../../core/domain/entities/sport.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../business_courts/domain/entities/court.dart';
import '../../../business_courts/presentation/widgets/court_pricing_card.dart';
import '../../../business_courts/presentation/widgets/court_summaries.dart';
import 'reservation_section_card.dart';

/// Motivo por el que una cancha no se puede reservar (o `null`).
String? notBookableReason(Court court) {
  if (court.isBookable) return null;
  if (!court.isActive) return 'Inactiva';
  return 'Faltan fotos';
}

IconData sportIcon(Sport? sport) => switch (sport) {
  Sport.futbol => Icons.sports_soccer,
  Sport.padel => Icons.sports_tennis,
  Sport.baloncesto => Icons.sports_basketball,
  Sport.voleibol => Icons.sports_volleyball,
  null => Icons.stadium_outlined,
};

/// Cancha y día de la reserva. Las canchas que no se pueden reservar se
/// listan deshabilitadas con su motivo; el día mínimo es hoy.
class CreateReservationCourtCard extends StatelessWidget {
  const CreateReservationCourtCard({
    super.key,
    required this.courts,
    required this.selectedCourt,
    required this.day,
    required this.minDay,
    required this.onCourtChanged,
    required this.onDayChanged,
  });

  final List<Court> courts;
  final Court? selectedCourt;
  final DateTime day;
  final DateTime minDay;
  final ValueChanged<Court> onCourtChanged;
  final ValueChanged<DateTime> onDayChanged;

  bool get _isMinDay =>
      day.year == minDay.year &&
      day.month == minDay.month &&
      day.day == minDay.day;

  static String courtSubtitle(Court court) =>
      '${CourtSummaries.sport(court.sport)} · '
      '${court.isCovered ? 'Cubierta' : 'Al aire libre'} · Turnos de '
      '${CourtPricingCard.durationLabel(court.slotDuration)}';

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: minDay,
      lastDate: minDay.add(const Duration(days: 365)),
      helpText: 'Día de la reserva',
    );
    if (picked != null) onDayChanged(picked);
  }

  void _showCourtPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Seleccionar cancha',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              for (final court in courts)
                _CourtTile(
                  court: court,
                  selected: court.id == selectedCourt?.id,
                  onTap: () {
                    onCourtChanged(court);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final court = selectedCourt;
    return ReservationSectionCard(
      icon: Icons.stadium_outlined,
      title: 'Cancha y fecha',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  sportIcon(court?.sport),
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      court?.name ?? 'Elige una cancha',
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (court != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        courtSubtitle(court),
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                key: const Key('change-court'),
                onPressed: () => _showCourtPicker(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceContainerLow,
                  visualDensity: VisualDensity.compact,
                ),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.expand_more, size: 18),
                label: const Text('Cambiar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Día anterior',
                  icon: const Icon(Icons.chevron_left, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLowest,
                  ),
                  // No se reserva en días pasados.
                  onPressed: _isMinDay
                      ? null
                      : () =>
                            onDayChanged(day.subtract(const Duration(days: 1))),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _dayLabel(day),
                              key: const Key('reservation-day'),
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isMinDay) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentLime,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Hoy',
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.onSecondaryFixed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Día siguiente',
                  icon: const Icon(Icons.chevron_right, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLowest,
                  ),
                  onPressed: () =>
                      onDayChanged(day.add(const Duration(days: 1))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _dayLabel(DateTime date) {
    const weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} de '
        '${months[date.month - 1]}';
  }
}

class _CourtTile extends StatelessWidget {
  const _CourtTile({
    required this.court,
    required this.selected,
    required this.onTap,
  });

  final Court court;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reason = notBookableReason(court);
    return ListTile(
      enabled: reason == null,
      onTap: onTap,
      leading: Icon(
        sportIcon(court.sport),
        color: selected ? AppColors.brandTeal : AppColors.onSurfaceVariant,
      ),
      title: Text(court.name),
      subtitle: Text(
        CreateReservationCourtCard.courtSubtitle(court),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: reason != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reason,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            )
          : selected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
    );
  }
}
