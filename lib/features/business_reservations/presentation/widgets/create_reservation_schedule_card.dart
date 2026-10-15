import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../business_courts/presentation/widgets/court_pricing_card.dart';
import '../../domain/entities/availability.dart';
import '../bloc/new_reservation/new_reservation_bloc.dart';
import 'reservation_section_card.dart';

/// Turnos del día con hora y precio. Se toca el turno inicial y luego la
/// duración (o un turno libre siguiente para extender el rango).
class CreateReservationScheduleCard extends StatelessWidget {
  const CreateReservationScheduleCard({
    super.key,
    required this.load,
    required this.availability,
    required this.startIndex,
    required this.slotCount,
    required this.maxSlotCount,
    required this.onSlotTap,
    required this.onCountChanged,
    required this.onRetry,
  });

  final AvailabilityLoad load;
  final Availability? availability;
  final int? startIndex;
  final int slotCount;
  final int maxSlotCount;
  final ValueChanged<int> onSlotTap;
  final ValueChanged<int> onCountChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final available = availability?.slots.where((s) => s.isAvailable).length;
    return ReservationSectionCard(
      icon: Icons.schedule,
      title: 'Horario y duración',
      badge: available == null || load != AvailabilityLoad.ready
          ? null
          : available == 1
          ? '1 libre'
          : '$available libres',
      child: switch (load) {
        AvailabilityLoad.idle => const _Info(
          icon: Icons.stadium_outlined,
          text: 'Elige una cancha para ver sus turnos.',
        ),
        AvailabilityLoad.loading => const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.brandTeal,
              ),
            ),
          ),
        ),
        AvailabilityLoad.failure => _Info(
          icon: Icons.cloud_off_outlined,
          text: 'No pudimos cargar los turnos.',
          action: TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ),
        AvailabilityLoad.ready => _slots(context, availability!),
      },
    );
  }

  Widget _slots(BuildContext context, Availability availability) {
    if (availability.isClosed) {
      return const _Info(
        icon: Icons.event_busy_outlined,
        text: 'La cancha no abre este día. Elige otra fecha.',
      );
    }
    // Los turnos que ya pasaron no se muestran (se conserva su índice).
    final visible = [
      for (final (i, slot) in availability.slots.indexed)
        if (slot.status != SlotStatus.past) (i, slot),
    ];
    if (visible.isEmpty) {
      return const _Info(
        icon: Icons.event_busy_outlined,
        text: 'Ya pasaron todos los turnos de este día. Elige otra fecha.',
      );
    }
    final start = startIndex;
    final end = start == null ? null : start + slotCount - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!availability.hasAvailable) ...[
          const _Info(
            icon: Icons.event_busy_outlined,
            text: 'No quedan turnos libres este día.',
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, slot) in visible)
              _SlotChip(
                key: Key('slot-$i'),
                slot: slot,
                selected: start != null && i >= start && i <= end!,
                isStart: i == start,
                onTap: slot.isAvailable ? () => onSlotTap(i) : null,
              ),
          ],
        ),
        const SizedBox(height: 10),
        const _Legend(),
        if (start != null) ...[
          const SizedBox(height: 16),
          Text(
            'DURACIÓN',
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
              for (var n = 1; n <= maxSlotCount; n++)
                ChoiceChip(
                  key: Key('slots-$n'),
                  label: Text(
                    CourtPricingCard.durationLabel(
                      n * availability.slotDuration,
                    ),
                  ),
                  selected: n == slotCount,
                  onSelected: (_) => onCountChanged(n),
                  showCheckmark: false,
                  selectedColor: AppColors.brandTeal,
                  labelStyle: AppTypography.labelMd.copyWith(
                    color: n == slotCount
                        ? AppColors.onPrimary
                        : AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (maxSlotCount < availability.maxSlots)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                maxSlotCount == 1
                    ? 'Solo queda este turno libre seguido.'
                    : 'Hay $maxSlotCount turnos libres seguidos desde aquí.',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandTealLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.timelapse, color: AppColors.brandTeal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppFormatters.timeRange(
                      availability.slots[start].start,
                      availability.slots[end!].end,
                    ),
                    key: const Key('selected-range'),
                    style: AppTypography.labelLg.copyWith(
                      color: AppColors.brandTealDeep,
                    ),
                  ),
                ),
                Text(
                  AppFormatters.cop(availability.priceFor(start, slotCount)),
                  style: AppTypography.labelLg.copyWith(
                    color: AppColors.brandTealDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    super.key,
    required this.slot,
    required this.selected,
    required this.isStart,
    required this.onTap,
  });

  final Slot slot;
  final bool selected;
  final bool isStart;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    // Ocupados en gris (no se pueden elegir).
    final (background, foreground) = selected
        ? (AppColors.brandTeal, AppColors.onPrimary)
        : enabled
        ? (AppColors.surfaceContainerLow, AppColors.onSurface)
        : (AppColors.slate200, AppColors.slate400);
    final status = switch (slot.status) {
      SlotStatus.available => selected ? 'elegido' : 'libre',
      SlotStatus.booked => 'ocupado',
      SlotStatus.past => 'ya pasó',
    };
    return Semantics(
      button: enabled,
      selected: selected,
      label:
          '${AppFormatters.time(slot.start)}, '
          '${AppFormatters.cop(slot.price)}, $status',
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 104,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isStart ? AppColors.brandTealDeep : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  AppFormatters.time(slot.start),
                  style: AppTypography.labelMd.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.cop(slot.price),
                  style: AppTypography.labelSm.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        item(AppColors.surfaceContainerLow, 'Libre'),
        item(AppColors.brandTeal, 'Elegido'),
        item(AppColors.slate200, 'Ocupado'),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}
