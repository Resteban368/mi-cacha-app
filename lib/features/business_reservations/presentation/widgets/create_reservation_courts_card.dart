import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/availability.dart';
import '../../domain/entities/new_reservation.dart';
import 'reservation_section_card.dart';

/// "Canchas a la vez": suma otras canchas libres en la misma franja del turno
/// elegido (para jugar varias canchas al mismo tiempo, hasta 3). Con
/// "Cualquier cancha" se elige cuántas canchas libres asignar.
class CreateReservationCourtsCard extends StatelessWidget {
  const CreateReservationCourtsCard({
    super.key,
    required this.anyCourt,
    required this.selectedCourts,
    required this.extraCourtIds,
    required this.addableCourts,
    required this.anyCourtCount,
    required this.anyCourtCountMax,
    required this.onExtraCourtToggled,
    required this.onAnyCourtCountChanged,
  });

  final bool anyCourt;

  /// La cancha elegida primero y las sumadas (o las que asignaría la API).
  final List<CourtSlots> selectedCourts;
  final List<String> extraCourtIds;
  final List<CourtSlots> addableCourts;
  final int anyCourtCount;
  final int anyCourtCountMax;
  final ValueChanged<String> onExtraCourtToggled;
  final ValueChanged<int> onAnyCourtCountChanged;

  @override
  Widget build(BuildContext context) {
    final hint = AppTypography.bodySm.copyWith(
      color: AppColors.onSurfaceVariant,
      fontSize: 12,
    );
    return ReservationSectionCard(
      icon: Icons.grid_view_rounded,
      title: 'Canchas a la vez',
      subtitle:
          'Para jugar varias canchas al mismo tiempo, en el mismo horario '
          '(máx. ${NewReservation.maxCourts}).',
      badge: selectedCourts.length > 1
          ? '${selectedCourts.length} canchas'
          : null,
      child: anyCourt ? _anyCourt(hint) : _byCourt(hint),
    );
  }

  Widget _byCourt(TextStyle hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, c) in selectedCourts.indexed)
              InputChip(
                key: Key('reservation-court-${c.court.id}'),
                label: Text(c.court.name),
                selected: true,
                showCheckmark: false,
                selectedColor: AppColors.brandTealLight,
                labelStyle: AppTypography.labelMd.copyWith(
                  color: AppColors.brandTealDeep,
                  fontWeight: FontWeight.w700,
                ),
                // La primera es la del turno tocado: se cambia en la grilla.
                onDeleted: i == 0
                    ? null
                    : () => onExtraCourtToggled(c.court.id),
                deleteButtonTooltipMessage: 'Quitar ${c.court.name}',
              ),
            for (final c in addableCourts)
              ActionChip(
                key: Key('reservation-add-court-${c.court.id}'),
                avatar: const Icon(Icons.add, size: 18),
                label: Text(c.court.name),
                side: BorderSide(color: AppColors.brandTeal),
                labelStyle: AppTypography.labelMd.copyWith(
                  color: AppColors.brandTeal,
                  fontWeight: FontWeight.w600,
                ),
                onPressed: () => onExtraCourtToggled(c.court.id),
              ),
          ],
        ),
        if (addableCourts.isEmpty &&
            selectedCourts.length < NewReservation.maxCourts) ...[
          const SizedBox(height: 8),
          Text('No hay otra cancha libre en ese mismo horario.', style: hint),
        ],
      ],
    );
  }

  Widget _anyCourt(TextStyle hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<int>(
          key: const Key('reservation-any-court-count'),
          showSelectedIcon: false,
          segments: [
            for (var n = 1; n <= NewReservation.maxCourts; n++)
              ButtonSegment(
                value: n,
                label: Text(n == 1 ? '1 cancha' : '$n canchas'),
                enabled: n <= anyCourtCountMax,
              ),
          ],
          selected: {anyCourtCount},
          onSelectionChanged: (s) => onAnyCourtCountChanged(s.first),
        ),
        const SizedBox(height: 8),
        Text(
          selectedCourts.isEmpty
              ? 'Elige un horario para ver qué canchas se asignan.'
              : 'Se asignan: ${selectedCourts.map((c) => c.court.name).join(' + ')}',
          style: hint,
        ),
      ],
    );
  }
}
