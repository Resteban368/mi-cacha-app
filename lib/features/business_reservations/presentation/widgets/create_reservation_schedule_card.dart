import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../business_courts/presentation/widgets/court_pricing_card.dart';
import '../../../business_courts/presentation/widgets/court_summaries.dart';
import '../../domain/entities/availability.dart';
import '../bloc/new_reservation/new_reservation_bloc.dart';
import 'create_reservation_shimmer.dart';
import 'reservation_section_card.dart';
import 'sport_style.dart';

/// Turnos del día de las canchas del deporte: una tarjeta por cancha o,
/// con "Cualquier cancha libre a esa hora", una sola grilla de horarios.
/// Se toca el turno inicial y luego la duración (o un turno libre siguiente
/// para extender el rango).
class CreateReservationScheduleCard extends StatefulWidget {
  const CreateReservationScheduleCard({
    super.key,
    required this.load,
    required this.availability,
    required this.hiddenCourtCount,
    required this.anyCourt,
    required this.selectedCourtId,
    required this.selectedStart,
    required this.selectedCourt,
    required this.selectedSlots,
    required this.slotCount,
    required this.maxSlotCount,
    required this.subtotal,
    required this.priceMayVary,
    required this.focusCourtId,
    required this.onAnyCourtChanged,
    required this.onSlotTap,
    required this.onCountChanged,
    required this.onRetry,
    required this.onManageCourts,
  });

  final AvailabilityLoad load;
  final SportAvailability? availability;

  /// Canchas del deporte que no aparecen (inactivas o sin fotos).
  final int hiddenCourtCount;
  final bool anyCourt;
  final String? selectedCourtId;
  final DateTime? selectedStart;

  /// Cancha del turno elegido (con [anyCourt], la que asignaría la API).
  final CourtSlots? selectedCourt;
  final List<Slot> selectedSlots;
  final int slotCount;
  final int maxSlotCount;
  final int? subtotal;
  final bool priceMayVary;

  /// Cancha cuya tarjeta se lleva a la vista al cargar.
  final String? focusCourtId;
  final ValueChanged<bool> onAnyCourtChanged;

  /// `courtId` es `null` en la grilla de "Cualquier cancha".
  final void Function(String? courtId, DateTime start) onSlotTap;
  final ValueChanged<int> onCountChanged;
  final VoidCallback onRetry;
  final VoidCallback onManageCourts;

  /// Ancho desde el que las tarjetas de cancha van en dos columnas.
  static const twoColumnsWidth = 720.0;

  @override
  State<CreateReservationScheduleCard> createState() =>
      _CreateReservationScheduleCardState();
}

class _CreateReservationScheduleCardState
    extends State<CreateReservationScheduleCard> {
  final _courtKeys = <String, GlobalKey>{};
  String? _focused;

  @override
  void initState() {
    super.initState();
    _scheduleFocus();
  }

  @override
  void didUpdateWidget(CreateReservationScheduleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleFocus();
  }

  /// Lleva a la vista la tarjeta de la cancha pedida, una sola vez.
  void _scheduleFocus() {
    final id = widget.focusCourtId;
    if (id == null || id == _focused || widget.anyCourt) return;
    if (widget.load != AvailabilityLoad.ready) return;
    _focused = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _courtKeys[id]?.currentContext;
      if (target == null || !target.mounted) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final availability = widget.availability;
    final ready = widget.load == AvailabilityLoad.ready && availability != null;
    final freeTimes = ready && widget.anyCourt
        ? availability.anyCourtSlots.where((s) => s.isAvailable).length
        : null;
    final firstCourt = ready ? availability.courts.firstOrNull : null;
    return ReservationSectionCard(
      icon: Icons.schedule,
      title: '2. Horario, duración y asignación de cancha',
      compact: true,
      subtitle: firstCourt == null
          ? null
          : 'Turnos de ${firstCourt.court.slotDuration} min · COP',
      trailing: ready && !availability.isEmpty
          ? _AnyCourtSwitch(
              value: widget.anyCourt,
              onChanged: widget.onAnyCourtChanged,
            )
          : null,
      badge: switch (freeTimes) {
        null => null,
        1 => '1 libre',
        final n => '$n libres',
      },
      child: switch (widget.load) {
        AvailabilityLoad.idle => const _Info(
          icon: Icons.sports_soccer,
          text: 'Elige un deporte para ver sus turnos.',
        ),
        AvailabilityLoad.loading =>
          const CourtSchedulesShimmer(courtCount: 2),
        AvailabilityLoad.failure => _Info(
          icon: Icons.cloud_off_outlined,
          text: 'No pudimos cargar los turnos.',
          action: TextButton(
            onPressed: widget.onRetry,
            child: const Text('Reintentar'),
          ),
        ),
        AvailabilityLoad.ready => _content(availability!),
      },
    );
  }

  Widget _content(SportAvailability availability) {
    final sport = CourtSummaries.sport(availability.sport).toLowerCase();
    final hidden = widget.hiddenCourtCount;
    final hiddenNotice = hidden == 0
        ? null
        : _Info(
            key: const Key('hidden-courts'),
            icon: Icons.visibility_off_outlined,
            text: hidden == 1
                ? '1 cancha de $sport no aparece porque está inactiva o le '
                      'faltan fotos.'
                : '$hidden canchas de $sport no aparecen porque están '
                      'inactivas o les faltan fotos.',
            action: TextButton(
              onPressed: widget.onManageCourts,
              child: const Text('Ir a Canchas'),
            ),
          );
    if (availability.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Info(
            icon: Icons.event_busy_outlined,
            text: 'No hay canchas de $sport disponibles.',
          ),
          if (hiddenNotice != null) ...[
            const SizedBox(height: 8),
            hiddenNotice,
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.anyCourt) ...[
          Text(
            'Eliges la hora y se asigna la primera cancha libre.',
            style: AppTypography.bodySm.copyWith(color: AppColors.slate500),
          ),
          const SizedBox(height: 10),
        ],
        if (hiddenNotice != null) ...[hiddenNotice, const SizedBox(height: 8)],
        if (widget.anyCourt)
          _anyCourtGrid(availability)
        else
          _courtCards(availability),
        const SizedBox(height: 14),
        _Legend(selectedStart: widget.selectedStart),
        if (widget.selectedStart != null && widget.selectedSlots.isNotEmpty)
          _selection(availability),
      ],
    );
  }

  Widget _anyCourtGrid(SportAvailability availability) {
    final all = availability.anyCourtSlots;
    if (all.isEmpty) {
      return const _Info(
        icon: Icons.event_busy_outlined,
        text: 'Ninguna cancha abre este día. Elige otra fecha.',
      );
    }
    // Los horarios que ya pasaron no se muestran (se conserva su índice).
    final visible = [
      for (final (i, slot) in all.indexed)
        if (slot.status != SlotStatus.past) (i, slot),
    ];
    if (visible.isEmpty) return const _AllPast();
    final start = widget.selectedStart;
    final end = _selectedEnd;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!visible.any((e) => e.$2.isAvailable)) ...[
          const _Info(
            icon: Icons.event_busy_outlined,
            text: 'No quedan turnos libres este día.',
          ),
          const SizedBox(height: 12),
        ],
        _SlotGrid(
          minColumns: 3,
          children: [
            for (final (i, slot) in visible)
              _SlotChip(
                key: Key('any-slot-$i'),
                start: slot.start,
                status: slot.status,
                price: slot.price,
                fromPrice: slot.priceVaries,
                selected: _inRange(slot.start, start, end),
                isStart: slot.start == start,
                onTap: slot.isAvailable
                    ? () => widget.onSlotTap(null, slot.start)
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  Widget _courtCards(SportAvailability availability) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >=
                CreateReservationScheduleCard.twoColumnsWidth
            ? 2
            : 1;
        final cards = [
          for (final court in availability.courts)
            _CourtSlotsCard(
              key: _courtKeys.putIfAbsent(court.court.id, GlobalKey.new),
              court: court,
              isSelectedCourt: court.court.id == widget.selectedCourtId,
              selectedStart: widget.selectedStart,
              selectedEnd: _selectedEnd,
              onSlotTap: (start) => widget.onSlotTap(court.court.id, start),
            ),
        ];
        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, card) in cards.indexed) ...[
                if (i > 0) const SizedBox(height: 10),
                card,
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i += 2) ...[
              if (i > 0) const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[i]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < cards.length
                        ? cards[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  /// Fin del último turno elegido.
  DateTime? get _selectedEnd => widget.selectedSlots.lastOrNull?.end;

  static bool _inRange(DateTime slotStart, DateTime? start, DateTime? end) =>
      start != null &&
      end != null &&
      !slotStart.isBefore(start) &&
      slotStart.isBefore(end);

  Widget _selection(SportAvailability availability) {
    final slots = widget.selectedSlots;
    final court = widget.selectedCourt;
    final duration = court?.court.slotDuration ?? 60;
    final max = widget.maxSlotCount;
    final subtotal = widget.subtotal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            for (var n = 1; n <= max; n++)
              ChoiceChip(
                key: Key('slots-$n'),
                label: Text(CourtPricingCard.durationLabel(n * duration)),
                selected: n == widget.slotCount,
                onSelected: (_) => widget.onCountChanged(n),
                showCheckmark: false,
                selectedColor: AppColors.brandTeal,
                labelStyle: AppTypography.labelMd.copyWith(
                  color: n == widget.slotCount
                      ? AppColors.onPrimary
                      : AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        if (max < availability.maxSlots)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              max == 1
                  ? 'Solo queda este turno libre seguido.'
                  : 'Hay $max turnos libres seguidos desde aquí.',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.timelapse, color: AppColors.brandTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppFormatters.timeRange(
                        slots.first.start,
                        slots.last.end,
                      ),
                      key: const Key('selected-range'),
                      style: AppTypography.labelLg.copyWith(
                        color: AppColors.brandTealDeep,
                      ),
                    ),
                  ),
                  if (subtotal != null)
                    Text(
                      AppFormatters.cop(subtotal),
                      style: AppTypography.labelLg.copyWith(
                        color: AppColors.brandTealDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              if (court != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.anyCourt
                      ? 'Se asignará ${court.court.name} si sigue libre'
                            '${widget.priceMayVary ? '; el valor puede '
                                      'cambiar según la cancha' : ''}.'
                      : court.court.name,
                  key: const Key('selected-court'),
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.brandTealDeep,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de una cancha: foto, nombre, tipo, turnos libres y su grilla.
class _CourtSlotsCard extends StatelessWidget {
  const _CourtSlotsCard({
    super.key,
    required this.court,
    required this.isSelectedCourt,
    required this.selectedStart,
    required this.selectedEnd,
    required this.onSlotTap,
  });

  final CourtSlots court;
  final bool isSelectedCourt;
  final DateTime? selectedStart;
  final DateTime? selectedEnd;
  final ValueChanged<DateTime> onSlotTap;

  static String subtitle(AvailabilityCourt court) =>
      '${CourtSummaries.sport(court.sport)} · '
      '${court.isCovered ? 'Cubierta' : 'Al aire libre'} · Turnos de '
      '${CourtPricingCard.durationLabel(court.slotDuration)}';

  @override
  Widget build(BuildContext context) {
    final info = court.court;
    final photo = info.photoUrl;
    // Los turnos que ya pasaron no se muestran (se conserva su índice).
    final visible = [
      for (final (i, slot) in court.slots.indexed)
        if (slot.status != SlotStatus.past) (i, slot),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelectedCourt
            ? AppColors.surface.withValues(alpha: 0.6)
            : AppColors.slate50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelectedCourt
              ? AppColors.brandTeal.withValues(alpha: 0.35)
              : AppColors.slate200,
          width: isSelectedCourt ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox.square(
                  dimension: 34,
                  child: photo == null
                      ? ColoredBox(
                          color: AppColors.surfaceContainerHigh,
                          child: Icon(
                            info.sport.icon,
                            color: AppColors.primary,
                          ),
                        )
                      : AppNetworkImage(
                          photo,
                          cacheWidth: 144,
                          semanticLabel: 'Foto de ${info.name}',
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name.toUpperCase(),
                      style: AppTypography.labelLg.copyWith(
                        color: AppColors.slate900,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle(info),
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelectedCourt
                        ? AppColors.brandTeal.withValues(alpha: 0.25)
                        : AppColors.slate200,
                  ),
                ),
                child: Text(
                  court.availableCount == 1
                      ? '1 Libre'
                      : '${court.availableCount} Libres',
                  style: AppTypography.labelSm.copyWith(
                    color: court.availableCount == 0
                        ? AppColors.slate400
                        : isSelectedCourt
                        ? AppColors.brandTeal
                        : AppColors.slate600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (court.isClosed)
            const _Info(
              icon: Icons.event_busy_outlined,
              text: 'No abre este día.',
            )
          else if (visible.isEmpty)
            const _AllPast()
          else
            _SlotGrid(
              minColumns: 3,
              children: [
                for (final (i, slot) in visible)
                  _SlotChip(
                    key: Key('slot-${info.id}-$i'),
                    start: slot.start,
                    status: slot.status,
                    price: slot.price,
                    selected:
                        isSelectedCourt &&
                        _CreateReservationScheduleCardState._inRange(
                          slot.start,
                          selectedStart,
                          selectedEnd,
                        ),
                    isStart: isSelectedCourt && slot.start == selectedStart,
                    onTap: slot.isAvailable
                        ? () => onSlotTap(slot.start)
                        : null,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    super.key,
    required this.start,
    required this.status,
    required this.price,
    required this.selected,
    required this.isStart,
    required this.onTap,
    this.fromPrice = false,
  });

  final DateTime start;
  final SlotStatus status;
  final int price;

  /// "desde $X": las canchas libres cobran distinto.
  final bool fromPrice;
  final bool selected;
  final bool isStart;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final label = status == SlotStatus.available
        ? (selected ? 'elegido' : 'libre')
        : status == SlotStatus.booked
        ? 'ocupado'
        : 'ya pasó';
    final priceText = '${fromPrice ? 'desde ' : ''}${AppFormatters.cop(price)}';
    // Libre: blanco con borde; elegido: teal con precio lima; ocupado: gris
    // tachado.
    final (background, border, timeColor, priceColor) = selected
        ? (
            AppColors.brandTeal,
            AppColors.brandTeal,
            AppColors.onPrimary,
            AppColors.accentLime,
          )
        : enabled
        ? (
            AppColors.surfaceContainerLowest,
            AppColors.slate200,
            AppColors.slate900,
            AppColors.slate500,
          )
        : (
            AppColors.slate200.withValues(alpha: 0.7),
            AppColors.slate200,
            AppColors.slate500,
            AppColors.slate400,
          );
    return Semantics(
      button: enabled,
      selected: selected,
      label: '${AppFormatters.time(start)}, $priceText, $label',
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled || selected ? 1 : 0.7,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: background,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isStart ? AppColors.brandTealDeep : border,
                      width: isStart ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          AppFormatters.time(start),
                          style: AppTypography.labelMd.copyWith(
                            color: timeColor,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w700,
                            decoration: status == SlotStatus.booked
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: timeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          selected && !fromPrice ? '$priceText COP' : priceText,
                          style: AppTypography.labelSm.copyWith(
                            color: priceColor,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Inicio elegido: marca de verificación en la esquina.
            if (isStart)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.onPrimary),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 11,
                    color: AppColors.accentLime,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Turnos en columnas iguales: tantas como quepan, con [minColumns] como
/// mínimo.
class _SlotGrid extends StatelessWidget {
  const _SlotGrid({required this.children, this.minColumns = 1});

  final List<Widget> children;
  final int minColumns;

  static const _gap = 6.0;
  static const _minSlotWidth = 92.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = ((width + _gap) ~/ (_minSlotWidth + _gap)).clamp(
          minColumns,
          8,
        );
        final slotWidth = (width - _gap * (columns - 1)) / columns;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final child in children)
              SizedBox(width: slotWidth, child: child),
          ],
        );
      },
    );
  }
}

class _AnyCourtSwitch extends StatelessWidget {
  const _AnyCourtSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.slate50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: const Key('any-court'),
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Cualquier cancha libre a esa hora',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.slate700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ExcludeSemantics(
                child: Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: AppColors.brandTeal,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.selectedStart});

  final DateTime? selectedStart;

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String text, {bool strong = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.slate200),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AppTypography.bodySm.copyWith(
              color: strong ? AppColors.slate900 : AppColors.slate600,
              fontWeight: strong ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
    final start = selectedStart;
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.slate100)),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 6,
        children: [
          item(AppColors.surfaceContainerLowest, 'Libre disponible'),
          item(
            AppColors.brandTeal,
            start == null
                ? 'Elegido'
                : 'Elegido (${AppFormatters.time(start)})',
            strong: start != null,
          ),
          item(AppColors.slate200, 'Ocupado / Reservado'),
        ],
      ),
    );
  }
}

class _AllPast extends StatelessWidget {
  const _AllPast();

  @override
  Widget build(BuildContext context) => const _Info(
    icon: Icons.event_busy_outlined,
    text: 'Ya pasaron todos los turnos de este día. Elige otra fecha.',
  );
}

class _Info extends StatelessWidget {
  const _Info({super.key, required this.icon, required this.text, this.action});

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
