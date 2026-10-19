import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/customer_failure.dart';
import '../../domain/entities/customer_query.dart';
import '../../domain/usecases/create_business_customer.dart';
import '../../domain/usecases/get_business_customers.dart';
import '../../domain/usecases/update_business_customer.dart';
import 'business_clients_event.dart';
import 'business_clients_state.dart';

class BusinessClientsBloc
    extends Bloc<BusinessClientsEvent, BusinessClientsState> {
  BusinessClientsBloc({
    required GetBusinessCustomers getBusinessCustomers,
    required CreateBusinessCustomer createBusinessCustomer,
    required UpdateBusinessCustomer updateBusinessCustomer,
    this.searchDebounce = const Duration(milliseconds: 300),
  }) : _getCustomers = getBusinessCustomers,
       _createCustomer = createBusinessCustomer,
       _updateCustomer = updateBusinessCustomer,
       super(const BusinessClientsState()) {
    on<BusinessClientsStarted>(_onStarted, transformer: restartable());
    on<BusinessClientsSearchChanged>(
      _onSearchChanged,
      transformer: restartable(),
    );
    on<BusinessClientsSegmentChanged>(
      _onSegmentChanged,
      transformer: restartable(),
    );
    on<BusinessClientsSortChanged>(_onSortChanged, transformer: restartable());
    // Cargar más: mientras carga una página se ignoran los demás pedidos.
    on<BusinessClientsNextPageRequested>(_onNextPage, transformer: droppable());
    on<BusinessClientsRefreshed>(_onRefreshed, transformer: restartable());
    on<BusinessClientsCustomerCreated>(
      _onCustomerCreated,
      transformer: droppable(),
    );
    on<BusinessClientsCustomerUpdated>(
      _onCustomerUpdated,
      transformer: droppable(),
    );
  }

  final GetBusinessCustomers _getCustomers;
  final CreateBusinessCustomer _createCustomer;
  final UpdateBusinessCustomer _updateCustomer;
  final Duration searchDebounce;

  /// Sube con cada consulta nueva (búsqueda, filtro, orden o recarga): las
  /// páginas que llegan de una consulta anterior se descartan.
  int _generation = 0;

  /// Carga la primera página de [query]; gana la última consulta.
  Future<void> _fetchCustomers(
    CustomerQuery query,
    Emitter<BusinessClientsState> emit,
  ) async {
    final generation = ++_generation;
    final first = query.copyWith(page: 1);
    emit(
      state.copyWith(
        status: ClientsStatus.loading,
        query: first,
        loadMore: LoadMoreStatus.idle,
        errorMessage: () => null,
      ),
    );

    try {
      final result = await _getCustomers(first);
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: ClientsStatus.success,
          result: () => result,
          items: () => result.items,
          errorMessage: () => null,
        ),
      );
    } on CustomerException catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          errorMessage: () => e.message ?? 'Error al cargar clientes.',
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: ClientsStatus.failure,
          errorMessage: () => 'Ocurrió un error inesperado al cargar clientes.',
        ),
      );
    }
  }

  Future<void> _onStarted(
    BusinessClientsStarted event,
    Emitter<BusinessClientsState> emit,
  ) async {
    await _fetchCustomers(event.query, emit);
  }

  Future<void> _onSearchChanged(
    BusinessClientsSearchChanged event,
    Emitter<BusinessClientsState> emit,
  ) async {
    if (event.search.isNotEmpty) {
      await Future<void>.delayed(searchDebounce);
      if (emit.isDone) return;
    }
    final newQuery = state.query.copyWith(search: event.search, page: 1);
    await _fetchCustomers(newQuery, emit);
  }

  Future<void> _onSegmentChanged(
    BusinessClientsSegmentChanged event,
    Emitter<BusinessClientsState> emit,
  ) async {
    final newQuery = state.query.copyWith(segment: event.segment, page: 1);
    await _fetchCustomers(newQuery, emit);
  }

  Future<void> _onSortChanged(
    BusinessClientsSortChanged event,
    Emitter<BusinessClientsState> emit,
  ) async {
    final newQuery = state.query.copyWith(sort: event.sort, page: 1);
    await _fetchCustomers(newQuery, emit);
  }

  /// Agrega la página siguiente a la lista (scroll infinito).
  Future<void> _onNextPage(
    BusinessClientsNextPageRequested event,
    Emitter<BusinessClientsState> emit,
  ) async {
    if (state.status != ClientsStatus.success || !state.hasNextPage) return;
    final generation = _generation;
    final next = state.query.copyWith(page: state.currentPage + 1);
    emit(state.copyWith(loadMore: LoadMoreStatus.loading));
    try {
      final result = await _getCustomers(next);
      // Cambió la búsqueda o el filtro mientras cargaba: se descarta.
      if (generation != _generation) return;
      final seen = {for (final c in state.clients) c.id};
      emit(
        state.copyWith(
          query: next,
          result: () => result,
          items: () => [
            ...state.clients,
            ...result.items.where((c) => !seen.contains(c.id)),
          ],
          loadMore: LoadMoreStatus.idle,
        ),
      );
    } catch (_) {
      if (generation != _generation) return;
      emit(state.copyWith(loadMore: LoadMoreStatus.failure));
    }
  }

  Future<void> _onRefreshed(
    BusinessClientsRefreshed event,
    Emitter<BusinessClientsState> emit,
  ) async {
    await _fetchCustomers(state.query, emit);
  }

  Future<void> _onCustomerCreated(
    BusinessClientsCustomerCreated event,
    Emitter<BusinessClientsState> emit,
  ) async {
    emit(
      state.copyWith(
        saveStatus: SaveCustomerStatus.saving,
        saveErrorMessage: () => null,
      ),
    );

    try {
      final created = await _createCustomer(event.payload);
      emit(
        state.copyWith(
          saveStatus: SaveCustomerStatus.success,
          lastSavedClient: () => created,
          saveErrorMessage: () => null,
        ),
      );
      // Reload current list
      await _fetchCustomers(state.query, emit);
    } on CustomerException catch (e) {
      emit(
        state.copyWith(
          saveStatus: SaveCustomerStatus.failure,
          saveErrorMessage: () =>
              e.message ?? 'No fue posible crear el cliente.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          saveStatus: SaveCustomerStatus.failure,
          saveErrorMessage: () => 'Error inesperado al crear el cliente.',
        ),
      );
    }
  }

  Future<void> _onCustomerUpdated(
    BusinessClientsCustomerUpdated event,
    Emitter<BusinessClientsState> emit,
  ) async {
    emit(
      state.copyWith(
        saveStatus: SaveCustomerStatus.saving,
        saveErrorMessage: () => null,
      ),
    );

    try {
      final updated = await _updateCustomer(
        UpdateCustomerParams(id: event.id, payload: event.payload),
      );
      emit(
        state.copyWith(
          saveStatus: SaveCustomerStatus.success,
          lastSavedClient: () => updated,
          saveErrorMessage: () => null,
        ),
      );
      // Reload current list
      await _fetchCustomers(state.query, emit);
    } on CustomerException catch (e) {
      emit(
        state.copyWith(
          saveStatus: SaveCustomerStatus.failure,
          saveErrorMessage: () =>
              e.message ?? 'No fue posible actualizar el cliente.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          saveStatus: SaveCustomerStatus.failure,
          saveErrorMessage: () => 'Error inesperado al actualizar el cliente.',
        ),
      );
    }
  }
}
