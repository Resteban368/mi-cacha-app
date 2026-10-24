import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../business_courts/domain/entities/court.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/reservation_query.dart';

/// Búsqueda (nombre, teléfono o cédula) y filtros por estado, cancha,
/// fechas y cliente.
class ReservationsFiltersBar extends StatelessWidget {
  const ReservationsFiltersBar({
    super.key,
    required this.query,
    required this.courts,
    required this.searchController,
    required this.onSearchChanged,
    required this.onQueryChanged,
    this.customerName,
  });

  final ReservationQuery query;
  final List<Court> courts;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  /// Filtros elegidos con los chips (sin espera).
  final ValueChanged<ReservationQuery> onQueryChanged;

  /// Nombre del cliente filtrado (historial de un cliente).
  final String? customerName;

  static String _statusLabel(ReservationStatus? status) =>
      status == null ? 'Estado' : status.label;

  Future<void> _pickDates(BuildContext context) async {
    final now = DateTime.now();
    final from = query.from;
    final to = query.to;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 2),
      initialDateRange: from != null && to != null
          ? DateTimeRange(start: from, end: to)
          : null,
      locale: const Locale('es', 'CO'),
      helpText: 'Rango de fechas',
      saveText: 'Aplicar',
    );
    if (range == null) return;
    onQueryChanged(
      query.copyWith(from: () => range.start, to: () => range.end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final court = courts.where((c) => c.id == query.courtId).firstOrNull;
    final from = query.from;
    final to = query.to;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('reservations-search'),
          controller: searchController,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Nombre, teléfono o cédula',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: ListenableBuilder(
              listenable: searchController,
              builder: (_, _) => searchController.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: 'Borrar búsqueda',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (customerName case final name?) ...[
                InputChip(
                  label: Text('Cliente: $name'),
                  onDeleted: () =>
                      onQueryChanged(query.copyWith(customerId: () => null)),
                ),
                const SizedBox(width: 8),
              ],
              FilterChip(
                key: const Key('filter-cancelled'),
                avatar: const Icon(Icons.event_busy_rounded, size: 18),
                label: const Text('Canceladas'),
                selected: query.status == ReservationStatus.cancelled,
                onSelected: (on) => onQueryChanged(
                  query.copyWith(
                    status: () => on ? ReservationStatus.cancelled : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _MenuChip<ReservationStatus?>(
                key: const Key('filter-status'),
                label: _statusLabel(query.status),
                active: query.status != null,
                options: [
                  (null, 'Todos los estados'),
                  for (final status in ReservationStatus.values)
                    (status, status.label),
                ],
                onSelected: (status) =>
                    onQueryChanged(query.copyWith(status: () => status)),
              ),
              const SizedBox(width: 8),
              if (courts.isNotEmpty) ...[
                _MenuChip<String?>(
                  key: const Key('filter-court'),
                  label: court?.name ?? 'Cancha',
                  active: court != null,
                  options: [
                    (null, 'Todas las canchas'),
                    for (final c in courts) (c.id, c.name),
                  ],
                  onSelected: (id) =>
                      onQueryChanged(query.copyWith(courtId: () => id)),
                ),
                const SizedBox(width: 8),
              ],
              if (from != null && to != null)
                InputChip(
                  key: const Key('filter-dates'),
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    '${AppFormatters.shortDate(from)} – '
                    '${AppFormatters.shortDate(to)}',
                  ),
                  selected: true,
                  showCheckmark: false,
                  onPressed: () => _pickDates(context),
                  onDeleted: () => onQueryChanged(
                    query.copyWith(from: () => null, to: () => null),
                  ),
                )
              else
                ActionChip(
                  key: const Key('filter-dates'),
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: const Text('Fechas'),
                  onPressed: () => _pickDates(context),
                ),
              if (query.hasFilters) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    searchController.clear();
                    onQueryChanged(const ReservationQuery());
                  },
                  child: const Text('Limpiar'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Chip con menú de opciones (estado, cancha).
class _MenuChip<T> extends StatelessWidget {
  const _MenuChip({
    super.key,
    required this.label,
    required this.active,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final bool active;
  final List<(T, String)> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        for (final (value, text) in options)
          MenuItemButton(onPressed: () => onSelected(value), child: Text(text)),
      ],
      builder: (context, controller, _) => FilterChip(
        label: Text(label),
        selected: active,
        showCheckmark: false,
        selectedColor: AppColors.brandTealLight,
        labelStyle: AppTypography.labelMd.copyWith(
          color: active ? AppColors.brandTealDeep : AppColors.onSurface,
        ),
        avatar: const Icon(Icons.arrow_drop_down, size: 18),
        onSelected: (_) =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
