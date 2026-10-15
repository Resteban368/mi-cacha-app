import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecase/usecase.dart';
import '../../../../business_courts/domain/entities/court.dart';
import '../../../../business_courts/domain/usecases/get_courts.dart';
import '../../../domain/entities/reservation.dart';
import '../../../domain/entities/reservation_query.dart';
import '../../../domain/usecases/booking_usecases.dart';

part 'reservations_list_event.dart';
part 'reservations_list_state.dart';

/// Todas las reservas del negocio con búsqueda y filtros, de 20 en 20.
///
/// - Buscar o filtrar reinicia la lista (gana la última; la búsqueda espera
///   a que se deje de escribir).
/// - "Cargar más" ignora pedidos mientras carga.
/// - Un contador de generación descarta páginas que llegan después de
///   cambiar los filtros.
class ReservationsListBloc
    extends Bloc<ReservationsListEvent, ReservationsListState> {
  ReservationsListBloc({
    required ListReservations listReservations,
    required GetCourts getCourts,
    this.searchDebounce = const Duration(milliseconds: 300),
  }) : _list = listReservations,
       _getCourts = getCourts,
       super(const ReservationsListState()) {
    on<ReservationsListQueryEvent>(_onQuery, transformer: restartable());
    on<ReservationsListMoreRequested>(_onMore, transformer: droppable());
  }

  final ListReservations _list;
  final GetCourts _getCourts;
  final Duration searchDebounce;

  /// Cambia con cada lista nueva; una página de otra generación se descarta.
  var _generation = 0;

  Future<void> _onQuery(
    ReservationsListQueryEvent event,
    Emitter<ReservationsListState> emit,
  ) async {
    final query = switch (event) {
      ReservationsListStarted(:final query) => query,
      ReservationsListQueryChanged(:final query) => query,
      ReservationsListRefreshed() => state.query,
    };
    final generation = ++_generation;
    final keepItems = event is ReservationsListRefreshed;
    emit(
      state.copyWith(
        query: query,
        status: keepItems && state.items.isNotEmpty
            ? state.status
            : ReservationsListStatus.loading,
        loadMoreFailed: false,
      ),
    );
    // Espera a que se deje de escribir (solo al cambiar el texto).
    if (event case ReservationsListQueryChanged(
      :final debounce,
    ) when debounce) {
      await Future<void>.delayed(searchDebounce);
      if (emit.isDone) return;
    }
    try {
      final courts = event is ReservationsListStarted
          ? _loadCourts()
          : Future.value(state.courts);
      final (page, courtList) = await (
        _list((query: query, page: 1)),
        courts,
      ).wait;
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: ReservationsListStatus.ready,
          items: page.items,
          total: page.total,
          page: page.page,
          hasMore: page.hasMore,
          courts: courtList,
        ),
      );
    } catch (_) {
      if (generation != _generation) return;
      emit(state.copyWith(status: ReservationsListStatus.failure));
    } finally {
      if (event case ReservationsListRefreshed(:final done?)) done.complete();
    }
  }

  /// Canchas para el filtro; si fallan, el listado funciona sin ese filtro.
  Future<List<Court>> _loadCourts() async {
    try {
      return await _getCourts(const NoParams());
    } catch (_) {
      return const [];
    }
  }

  Future<void> _onMore(
    ReservationsListMoreRequested event,
    Emitter<ReservationsListState> emit,
  ) async {
    if (state.status != ReservationsListStatus.ready || !state.hasMore) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(loadingMore: true, loadMoreFailed: false));
    try {
      final page = await _list((query: state.query, page: state.page + 1));
      if (generation != _generation) return;
      emit(
        state.copyWith(
          items: [...state.items, ...page.items],
          total: page.total,
          page: page.page,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (generation != _generation) return;
      emit(state.copyWith(loadingMore: false, loadMoreFailed: true));
    }
  }
}
