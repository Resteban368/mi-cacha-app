import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/loading_dialog.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/reservation_query.dart';
import '../bloc/reservation_detail/reservation_detail_cubit.dart';
import '../bloc/reservations_list/reservations_list_bloc.dart';
import '../widgets/reservation_detail_sheet.dart';
import '../widgets/reservation_list_tile.dart';
import '../widgets/reservations_filters_bar.dart';

/// Todas las reservas del negocio, de la más reciente a la más antigua, con
/// búsqueda y filtros. Se cargan de 20 en 20 al bajar.
class BusinessReservationsListPage extends StatefulWidget {
  const BusinessReservationsListPage({
    super.key,
    required this.createDetailCubit,
    this.customerName,
  });

  final ReservationDetailCubit Function() createDetailCubit;

  /// Nombre del cliente si se abrió su historial.
  final String? customerName;

  @override
  State<BusinessReservationsListPage> createState() =>
      _BusinessReservationsListPageState();
}

class _BusinessReservationsListPageState
    extends State<BusinessReservationsListPage> {
  /// Se piden más cuando quedan menos de estos píxeles por recorrer.
  static const _loadMoreThreshold = 600.0;

  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.text = context.read<ReservationsListBloc>().state.query.search;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  ReservationsListBloc get _bloc => context.read<ReservationsListBloc>();

  void _onSearchChanged(String text) => _bloc.add(
    ReservationsListQueryChanged(
      _bloc.state.query.copyWith(search: text),
      debounce: true,
    ),
  );

  Future<void> _openDetail(Reservation reservation) async {
    final bloc = _bloc;
    final changed = await showReservationDetail(
      context,
      reservation: reservation,
      createCubit: widget.createDetailCubit,
    );
    if (changed) bloc.add(const ReservationsListRefreshed());
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < _loadMoreThreshold) {
      final state = _bloc.state;
      if (state.hasMore && !state.loadingMore && !state.loadMoreFailed) {
        _bloc.add(const ReservationsListMoreRequested());
      }
    }
    return false;
  }

  Future<void> _refresh() {
    final done = Completer<void>();
    _bloc.add(ReservationsListRefreshed(done: done));
    return done.future;
  }

  @override
  Widget build(BuildContext context) {
    return BlocLoadingDialog<ReservationsListBloc, ReservationsListState>(
      // Solo la primera carga; al filtrar se ve una barra fina arriba.
      isLoading: (s) =>
          s.status == ReservationsListStatus.loading && s.page == 0,
      child: Column(
        children: [
          AppTopBar(
            title: 'Todas las reservas',
            subtitle: 'Historial y búsqueda',
            icon: Icons.list_alt_rounded,
            onBack: () => context.go(AppRoutes.businessReservations),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: BlocBuilder<ReservationsListBloc, ReservationsListState>(
                builder: (context, state) => LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    final gutter = isWide ? 24.0 : 16.0;
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 8),
                          child: ReservationsFiltersBar(
                            query: state.query,
                            courts: state.courts,
                            customerName: state.query.customerId == null
                                ? null
                                : widget.customerName ?? 'elegido',
                            searchController: _search,
                            onSearchChanged: _onSearchChanged,
                            onQueryChanged: (query) =>
                                _bloc.add(ReservationsListQueryChanged(query)),
                          ),
                        ),
                        SizedBox(
                          height: 3,
                          child:
                              state.status == ReservationsListStatus.loading &&
                                  state.page > 0
                              ? const LinearProgressIndicator(
                                  color: AppColors.brandTeal,
                                )
                              : null,
                        ),
                        Expanded(child: _results(state, isWide, gutter)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _results(ReservationsListState state, bool isWide, double gutter) {
    if (state.status == ReservationsListStatus.failure && state.items.isEmpty) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        title: 'No pudimos cargar las reservas',
        actionLabel: 'Reintentar',
        onAction: () => _bloc.add(const ReservationsListRefreshed()),
      );
    }
    if (state.status == ReservationsListStatus.ready && state.items.isEmpty) {
      return state.query.hasFilters
          ? _Message(
              icon: Icons.search_off_rounded,
              title: 'No hay reservas con estos filtros',
              actionLabel: 'Limpiar filtros',
              onAction: () {
                _search.clear();
                _bloc.add(
                  const ReservationsListQueryChanged(ReservationQuery()),
                );
              },
            )
          : _Message(
              icon: Icons.event_note_outlined,
              title: 'Aún no tienes reservas',
              actionLabel: 'Crear una reserva',
              onAction: () => context.go(AppRoutes.businessNewReservation),
            );
    }
    final busy = state.status == ReservationsListStatus.loading;
    return RefreshIndicator(
      color: AppColors.brandTeal,
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: AnimatedOpacity(
          // Mientras llegan los resultados de otro filtro.
          opacity: busy ? 0.5 : 1,
          duration: const Duration(milliseconds: 150),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    state.total == 1 ? '1 reserva' : '${state.total} reservas',
                    key: const Key('reservations-total'),
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isWide ? 520 : 720,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 12,
                    mainAxisExtent: ReservationListTile.height,
                  ),
                  itemCount: state.items.length,
                  itemBuilder: (context, i) {
                    final reservation = state.items[i];
                    return ReservationListTile(
                      key: ValueKey(reservation.id),
                      reservation: reservation,
                      onTap: () => _openDetail(reservation),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(child: _Footer(state: state)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pie del listado: cargando más, reintentar o fin.
class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final ReservationsListState state;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 24;
    if (state.loadingMore) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
        child: const Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.brandTeal,
            ),
          ),
        ),
      );
    }
    if (state.loadMoreFailed) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
        child: Center(
          child: TextButton.icon(
            onPressed: () => context.read<ReservationsListBloc>().add(
              const ReservationsListMoreRequested(),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('No pudimos cargar más. Reintentar'),
          ),
        ),
      );
    }
    if (!state.hasMore && state.items.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
        child: Text(
          'No hay más reservas',
          textAlign: TextAlign.center,
          style: AppTypography.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }
    return SizedBox(height: bottom);
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.brandTeal),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
