import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/sliver_card_grid.dart';
import '../../domain/entities/court_occupancy.dart';
import '../../domain/entities/day_agenda.dart';
import '../../domain/entities/reservation.dart';
import '../bloc/business_reservations_bloc.dart';
import '../widgets/agenda_metric_cards.dart';
import '../widgets/court_occupancy_header.dart';
import '../widgets/day_header.dart';
import '../widgets/live_reservation_card.dart';
import '../bloc/reservation_detail/reservation_detail_cubit.dart';
import '../widgets/new_reservation_fab.dart';
import '../widgets/reservation_detail_sheet.dart';
import '../widgets/reservation_card.dart';
import '../widgets/reservation_filter_chips.dart';
import '../widgets/timeline_markers.dart';
import '../../../../core/widgets/loading_dialog.dart';
import '../../../../core/session/write_access.dart';

/// Pestaña "Reservas" del home de negocio (diseño "Reservas de Hoy").
class BusinessReservationsPage extends StatefulWidget {
  const BusinessReservationsPage({
    super.key,
    this.createDetailCubit,
    this.newReservations,
  });

  /// Crea el cubit del detalle de una reserva; sin él, las reservas no se
  /// abren (p. ej. en tests de la agenda).
  final ReservationDetailCubit Function()? createDetailCubit;

  /// Avisa cuando llega una reserva nueva con la app abierta: recarga la
  /// agenda y muestra un aviso breve.
  final Stream<void>? newReservations;

  @override
  State<BusinessReservationsPage> createState() =>
      _BusinessReservationsPageState();
}

class _BusinessReservationsPageState extends State<BusinessReservationsPage> {
  String? _selectedReservationId;
  StreamSubscription<void>? _newReservations;

  @override
  void initState() {
    super.initState();
    _newReservations = widget.newReservations?.listen((_) {
      if (!mounted) return;
      context.read<BusinessReservationsBloc>().add(
        const ReservationsRefreshed(),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Llegó una reserva nueva')),
        );
    });
  }

  @override
  void dispose() {
    _newReservations?.cancel();
    super.dispose();
  }

  /// Vista de la agenda: por hora (línea de tiempo) o agrupada por cancha.
  bool _groupByCourt = false;

  Future<void> _openDetail(
    BuildContext context,
    Reservation reservation,
  ) async {
    final create = widget.createDetailCubit;
    if (create == null) return;
    final bloc = context.read<BusinessReservationsBloc>();
    final changed = await showReservationDetail(
      context,
      reservation: reservation,
      createCubit: create,
    );
    if (changed) bloc.add(const ReservationsRefreshed());
  }

  void _changeDay(BuildContext context, DateTime? day) {
    context.read<BusinessReservationsBloc>().add(ReservationsRequested(day));
  }

  Future<void> _pickDate(BuildContext context, DateTime currentDay) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Seleccionar día de agenda',
      confirmText: 'Ver agenda',
      cancelText: 'Cancelar',
    );
    if (picked != null && context.mounted) {
      _changeDay(context, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Al cargar: diálogo con el ícono de la app sobre el fondo difuminado.
    return BlocLoadingDialog<
      BusinessReservationsBloc,
      BusinessReservationsState
    >(
      isLoading: (s) =>
          s.status == ReservationsStatus.initial ||
          s.status == ReservationsStatus.loading,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Con Scaffold.extendBody, padding.bottom incluye la barra inferior.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        Column(
          children: [
            const AppTopBar(
              title: 'Reservas',
              subtitle: 'Agenda de tus canchas',
              icon: Icons.event_note_rounded,
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child:
                    BlocBuilder<
                      BusinessReservationsBloc,
                      BusinessReservationsState
                    >(
                      builder: (context, state) => LayoutBuilder(
                        builder: (context, constraints) {
                          final layout = CardGridLayout.of(
                            constraints.maxWidth,
                          );

                          return RefreshIndicator(
                            color: AppColors.brandTeal,
                            onRefresh: () => _refresh(context),
                            child: CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: layout
                                        .paddingBeyond(0)
                                        .copyWith(top: 12),
                                    child: DayHeader(
                                      day: state.day,
                                      isToday: state.agenda.isToday,
                                      onPreviousDay: () => _changeDay(
                                        context,
                                        state.day.subtract(
                                          const Duration(days: 1),
                                        ),
                                      ),
                                      onNextDay: () => _changeDay(
                                        context,
                                        state.day.add(const Duration(days: 1)),
                                      ),
                                      onJumpToday: () =>
                                          _changeDay(context, null),
                                      onOpenCalendar: () =>
                                          _pickDate(context, state.day),
                                    ),
                                  ),
                                ),
                                if (state.status ==
                                        ReservationsStatus.success &&
                                    state.agenda.reservations.isNotEmpty) ...[
                                  const SliverToBoxAdapter(
                                    child: SizedBox(height: 10),
                                  ),
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: layout.paddingBeyond(0),
                                      child: AgendaMetricCards(
                                        agenda: state.agenda,
                                      ),
                                    ),
                                  ),
                                ],
                                // Vista por hora / por cancha y acceso al listado.
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: layout
                                        .paddingBeyond(4)
                                        .add(
                                          const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                    child: Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        SegmentedButton<bool>(
                                          key: const Key('agenda-view'),
                                          showSelectedIcon: false,
                                          style: SegmentedButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          segments: const [
                                            ButtonSegment(
                                              value: false,
                                              icon: Icon(
                                                Icons.schedule_rounded,
                                                size: 18,
                                              ),
                                              label: Text('Por hora'),
                                            ),
                                            ButtonSegment(
                                              value: true,
                                              icon: Icon(
                                                Icons.sports_soccer_rounded,
                                                size: 18,
                                              ),
                                              label: Text('Por cancha'),
                                            ),
                                          ],
                                          selected: {_groupByCourt},
                                          onSelectionChanged: (v) => setState(
                                            () => _groupByCourt = v.first,
                                          ),
                                        ),
                                        TextButton.icon(
                                          key: const Key('all-reservations'),
                                          onPressed: () => context.go(
                                            AppRoutes.businessAllReservations,
                                          ),
                                          icon: const Icon(
                                            Icons.list_alt_rounded,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Ver todas las reservas',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                ..._content(
                                  context,
                                  state,
                                  layout,
                                  bottomInset,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
              ),
            ),
          ],
        ),
        // En solo lectura no se ofrece crear reservas.
        if (WriteAccessScope.canWrite(context))
          Positioned(
            right: 16,
            bottom: bottomInset + 16,
            child: NewReservationFab(
              onPressed: () => context.go(AppRoutes.businessNewReservation),
            ),
          ),
      ],
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<BusinessReservationsBloc>()
      ..add(const ReservationsRefreshed());
    await bloc.stream.firstWhere((s) => !s.isRefreshing);
  }

  List<Widget> _content(
    BuildContext context,
    BusinessReservationsState state,
    CardGridLayout layout,
    double bottomInset,
  ) {
    switch (state.status) {
      case ReservationsStatus.initial || ReservationsStatus.loading:
        return const [
          // La carga se muestra con el diálogo (BlocLoadingDialog).
          SliverFillRemaining(hasScrollBody: false, child: SizedBox.shrink()),
        ];
      case ReservationsStatus.failure:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _Message(
              icon: Icons.cloud_off_outlined,
              title: 'No pudimos cargar las reservas',
              message: 'Revisa tu conexión e intenta de nuevo.',
              action: 'Reintentar',
              onAction: () => context.read<BusinessReservationsBloc>().add(
                ReservationsRequested(state.day),
              ),
            ),
          ),
        ];
      case ReservationsStatus.success:
        final agenda = state.agenda;
        if (agenda.reservations.isEmpty) {
          return const [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _Message(
                icon: Icons.event_available_outlined,
                title: 'Sin reservas para este día',
                message: 'Las nuevas reservas aparecerán aquí.',
              ),
            ),
          ];
        }
        final sections = _timeline(context, state, agenda);
        final gutter = EdgeInsets.symmetric(horizontal: layout.gutter);
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: layout
                  .paddingBeyond(12)
                  .add(const EdgeInsets.only(bottom: 4)),
              child: ReservationFilterChips(
                agenda: agenda,
                selected: state.filter,
                onToggle: (filter) => context
                    .read<BusinessReservationsBloc>()
                    .add(ReservationsFilterToggled(filter)),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          if (sections.isEmpty)
            const SliverToBoxAdapter(
              child: _Message(
                icon: Icons.filter_alt_off_outlined,
                title: 'Nada por aquí',
                message: 'No hay reservas con este filtro.',
              ),
            ),
          for (final section in sections) ...[
            if (section.header != null)
              SliverPadding(
                padding: gutter.copyWith(bottom: 10),
                sliver: SliverToBoxAdapter(child: section.header),
              ),
            if (section.cards.isNotEmpty)
              SliverPadding(
                padding: gutter.copyWith(bottom: 10),
                sliver: SliverCardGrid(
                  itemCount: section.cards.length,
                  itemBuilder: (_, i) => section.cards[i],
                  columns: layout.columns,
                ),
              ),
          ],
          // Espacio final para el botón flotante y la barra inferior.
          SliverToBoxAdapter(child: SizedBox(height: bottomInset + 78)),
        ];
    }
  }

  /// Hoy y sin filtro: secciones Pasadas / Ahora + en juego / Próximas.
  /// Con filtro u otro día: una sola sección sin encabezado.
  List<_Section> _timeline(
    BuildContext context,
    BusinessReservationsState state,
    DayAgenda agenda,
  ) {
    final now = agenda.now;

    Widget card(Reservation r) {
      final timing = r.timingAt(now);
      final isLive = !r.isVoid && timing == ReservationTiming.live;
      final isSelected = r.id == _selectedReservationId;
      final child = isLive
          ? LiveReservationCard(
              reservation: r,
              isSelected: isSelected,
              onQuickCollect: () => _openDetail(context, r),
            )
          : ReservationCard(
              reservation: r,
              timing: timing,
              isSelected: isSelected,
              onQuickCollect: () => _openDetail(context, r),
            );
      // Tocar la reserva abre su detalle (cancelar, marcar jugada…).
      return Semantics(
        key: ValueKey(r.id),
        button: true,
        onTapHint: 'ver detalle',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => _selectedReservationId = r.id);
            _openDetail(context, r);
          },
          child: child,
        ),
      );
    }

    if (_groupByCourt) {
      final byCourt = <String, List<Reservation>>{};
      for (final r in agenda.filtered(state.filter)) {
        byCourt.putIfAbsent(r.courtName, () => []).add(r);
      }
      // Ocupación solo sin otro filtro: con "En vivo", "Canceladas"… no aplica.
      final showOccupancy = state.filter == null;
      final occupancy = {
        for (final o in CourtOccupancy.forDay(state.courts, agenda)) o.name: o,
      };
      // Solo las canchas con reservas: las vacías ocupan espacio sin aportar.
      final names = byCourt.keys.toList()..sort();
      return [
        for (final name in names)
          _Section(
            header: CourtOccupancyHeader(
              name: name,
              count: byCourt[name]?.length ?? 0,
              occupancy: showOccupancy ? occupancy[name] : null,
            ),
            cards: [
              for (final r in [
                ...?byCourt[name],
              ]..sort((a, b) => a.start.compareTo(b.start)))
                card(r),
            ],
          ),
      ];
    }

    if (state.filter != null || !agenda.isToday) {
      final cards = agenda.filtered(state.filter).map(card).toList();
      return [if (cards.isNotEmpty) _Section(cards: cards)];
    }

    final past = <Reservation>[];
    final live = <Reservation>[];
    final upcoming = <Reservation>[];
    for (final r in agenda.reservations) {
      switch (r.timingAt(now)) {
        case ReservationTiming.past:
          past.add(r);
        case _ when r.isVoid:
          past.add(r);
        case ReservationTiming.live:
          live.add(r);
        case ReservationTiming.upcoming:
          upcoming.add(r);
      }
    }

    return [
      if (past.isNotEmpty)
        _Section(
          header: const TimelineSectionLabel('Pasadas'),
          cards: [for (final r in past) Opacity(opacity: 0.8, child: card(r))],
        ),
      _Section(
        header: NowMarker(now: now),
        cards: live.map(card).toList(),
      ),
      if (upcoming.isNotEmpty)
        _Section(
          header: TimelineSectionLabel(
            now.hour >= 18 ? 'Próximas para esta noche' : 'Próximas para hoy',
          ),
          cards: upcoming.map(card).toList(),
        ),
    ];
  }
}

class _Section {
  const _Section({this.header, required this.cards});

  final Widget? header;
  final List<Widget> cards;
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.brandTealLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: AppColors.brandTeal),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandTeal,
              ),
              child: Text(action!),
            ),
          ],
        ],
      ),
    );
  }
}
