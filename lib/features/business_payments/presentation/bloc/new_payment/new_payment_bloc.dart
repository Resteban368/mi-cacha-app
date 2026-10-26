import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../business_clients/domain/entities/client_filter.dart';
import '../../../../business_clients/domain/entities/client_profile.dart';
import '../../../../business_clients/domain/entities/customer_query.dart';
import '../../../../business_clients/domain/usecases/get_business_customers.dart';
import '../../../../business_reservations/domain/entities/customer.dart';
import '../../../../business_reservations/domain/entities/reservation.dart';
import '../../../../business_reservations/domain/entities/reservation_query.dart';
import '../../../../business_reservations/domain/usecases/booking_usecases.dart';
import '../../../domain/entities/new_payment.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/usecases/create_payment.dart';

part 'new_payment_event.dart';
part 'new_payment_state.dart';

class NewPaymentBloc extends Bloc<NewPaymentEvent, NewPaymentState> {
  NewPaymentBloc({
    required CreatePayment createPayment,
    required GetBusinessCustomers getBusinessCustomers,
    required ListReservations listReservations,
    this.searchDebounce = const Duration(milliseconds: 250),
  }) : _createPayment = createPayment,
       _getCustomers = getBusinessCustomers,
       _listReservations = listReservations,
       super(const NewPaymentState()) {
    on<NewPaymentStarted>(_onStarted, transformer: restartable());
    on<NewPaymentTargetModeChanged>(_onTargetModeChanged);
    on<NewPaymentCustomerSearchChanged>(
      _onCustomerSearchChanged,
      transformer: restartable(),
    );
    // Cargar más clientes: se ignoran los pedidos mientras carga una página.
    on<NewPaymentCustomersNextPage>(
      _onCustomersNextPage,
      transformer: droppable(),
    );
    on<NewPaymentCustomerSelected>(_onCustomerSelected);
    on<NewPaymentReservationSearchChanged>(
      _onReservationSearchChanged,
      transformer: restartable(),
    );
    on<NewPaymentReservationSelected>(_onReservationSelected);
    // droppable: evita registrar dos veces el mismo pago.
    on<NewPaymentSubmitted>(_onSubmitted, transformer: droppable());
  }

  final CreatePayment _createPayment;
  final GetBusinessCustomers _getCustomers;
  final ListReservations _listReservations;

  /// Páginas que se recorren como máximo buscando reservas con saldo.
  static const _maxPendingPages = 5;

  /// Solo las reservas a las que les falta pagar (sin las canceladas). La
  /// API no filtra por saldo: se recorren páginas hasta juntar una página
  /// llena o acabarse los resultados.
  Future<List<Reservation>> _pendingReservations(ReservationQuery query) async {
    final pending = <Reservation>[];
    for (var page = 1; page <= _maxPendingPages; page++) {
      final result = await _listReservations((query: query, page: page));
      pending.addAll(
        result.items.where(
          (r) => !r.isFullyPaid && r.status != ReservationStatus.cancelled,
        ),
      );
      if (pending.length >= result.pageSize || !result.hasMore) break;
    }
    return pending;
  }

  final Duration searchDebounce;

  static const customersPageSize = 20;

  /// Sube con cada búsqueda de clientes: las páginas que llegan tarde de una
  /// búsqueda anterior se descartan.
  int _customerGeneration = 0;
  String _customerQuery = '';

  static Customer _toCustomer(ClientProfile c) => Customer(
    id: c.id,
    name: c.name,
    phone: c.phone,
    documentId: c.documentId,
  );

  Future<({List<Customer> items, bool hasMore})> _customersPage(
    String search,
    int page,
  ) async {
    final result = await _getCustomers(
      CustomerQuery(
        page: page,
        pageSize: customersPageSize,
        search: search,
        sort: ClientSortBy.recent,
      ),
    );
    return (
      items: result.items.map(_toCustomer).toList(),
      hasMore: result.hasNextPage,
    );
  }

  Future<void> _onStarted(
    NewPaymentStarted event,
    Emitter<NewPaymentState> emit,
  ) async {
    emit(
      state.copyWith(
        customerSearchStatus: EntitySearchStatus.loading,
        reservationSearchStatus: EntitySearchStatus.loading,
      ),
    );

    try {
      final generation = ++_customerGeneration;
      _customerQuery = '';
      final (customers, reservations) = await (
        _customersPage('', 1),
        _pendingReservations(const ReservationQuery()),
      ).wait;
      if (generation != _customerGeneration) return;

      emit(
        state.copyWith(
          customerResults: customers.items,
          customerPage: 1,
          customerHasMore: customers.hasMore,
          customerLoadMoreStatus: EntitySearchStatus.idle,
          customerSearchStatus: EntitySearchStatus.ready,
          reservationResults: reservations,
          reservationSearchStatus: EntitySearchStatus.ready,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          customerSearchStatus: EntitySearchStatus.failure,
          reservationSearchStatus: EntitySearchStatus.failure,
        ),
      );
    }
  }

  void _onTargetModeChanged(
    NewPaymentTargetModeChanged event,
    Emitter<NewPaymentState> emit,
  ) {
    if (event.mode == state.targetMode) return;
    emit(state.copyWith(targetMode: event.mode));
  }

  Future<void> _onCustomerSearchChanged(
    NewPaymentCustomerSearchChanged event,
    Emitter<NewPaymentState> emit,
  ) async {
    emit(state.copyWith(customerSearchStatus: EntitySearchStatus.loading));
    if (event.query.isNotEmpty) {
      await Future<void>.delayed(searchDebounce);
      if (emit.isDone) return;
    }
    final generation = ++_customerGeneration;
    _customerQuery = event.query.trim();

    try {
      final page = await _customersPage(_customerQuery, 1);
      if (emit.isDone || generation != _customerGeneration) return;
      emit(
        state.copyWith(
          customerResults: page.items,
          customerPage: 1,
          customerHasMore: page.hasMore,
          customerLoadMoreStatus: EntitySearchStatus.idle,
          customerSearchStatus: EntitySearchStatus.ready,
        ),
      );
    } catch (_) {
      if (emit.isDone || generation != _customerGeneration) return;
      emit(state.copyWith(customerSearchStatus: EntitySearchStatus.failure));
    }
  }

  /// Agrega la página siguiente de clientes (scroll infinito).
  Future<void> _onCustomersNextPage(
    NewPaymentCustomersNextPage event,
    Emitter<NewPaymentState> emit,
  ) async {
    if (state.customerSearchStatus != EntitySearchStatus.ready ||
        !state.customerHasMore) {
      return;
    }
    final generation = _customerGeneration;
    emit(state.copyWith(customerLoadMoreStatus: EntitySearchStatus.loading));
    try {
      final page = await _customersPage(_customerQuery, state.customerPage + 1);
      // Cambió la búsqueda mientras cargaba: se descarta.
      if (generation != _customerGeneration) return;
      final seen = {for (final c in state.customerResults) c.id};
      emit(
        state.copyWith(
          customerResults: [
            ...state.customerResults,
            ...page.items.where((c) => !seen.contains(c.id)),
          ],
          customerPage: state.customerPage + 1,
          customerHasMore: page.hasMore,
          customerLoadMoreStatus: EntitySearchStatus.idle,
        ),
      );
    } catch (_) {
      if (generation != _customerGeneration) return;
      emit(state.copyWith(customerLoadMoreStatus: EntitySearchStatus.failure));
    }
  }

  Future<void> _onCustomerSelected(
    NewPaymentCustomerSelected event,
    Emitter<NewPaymentState> emit,
  ) async {
    final customer = event.customer;
    if (customer == null) {
      emit(
        state.copyWith(
          selectedCustomer: () => null,
          customerReservations: const [],
          customerReservationsStatus: EntitySearchStatus.idle,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        selectedCustomer: () => customer,
        customerReservationsStatus: EntitySearchStatus.loading,
      ),
    );

    try {
      final reservations = await _pendingReservations(
        ReservationQuery(customerId: customer.id),
      );
      if (emit.isDone) return;
      emit(
        state.copyWith(
          customerReservations: reservations,
          customerReservationsStatus: EntitySearchStatus.ready,
        ),
      );
    } catch (_) {
      if (emit.isDone) return;
      emit(
        state.copyWith(customerReservationsStatus: EntitySearchStatus.failure),
      );
    }
  }

  Future<void> _onReservationSearchChanged(
    NewPaymentReservationSearchChanged event,
    Emitter<NewPaymentState> emit,
  ) async {
    emit(state.copyWith(reservationSearchStatus: EntitySearchStatus.loading));
    if (event.query.isNotEmpty) {
      await Future<void>.delayed(searchDebounce);
      if (emit.isDone) return;
    }

    try {
      final reservations = await _pendingReservations(
        ReservationQuery(search: event.query),
      );
      if (emit.isDone) return;
      emit(
        state.copyWith(
          reservationResults: reservations,
          reservationSearchStatus: EntitySearchStatus.ready,
        ),
      );
    } catch (_) {
      if (emit.isDone) return;
      emit(state.copyWith(reservationSearchStatus: EntitySearchStatus.failure));
    }
  }

  void _onReservationSelected(
    NewPaymentReservationSelected event,
    Emitter<NewPaymentState> emit,
  ) {
    final reservation = event.reservation;
    if (reservation == null) {
      emit(state.copyWith(selectedReservation: () => null));
      return;
    }

    emit(
      state.copyWith(
        selectedReservation: () => reservation,
        selectedCustomer: () => reservation.customer,
      ),
    );
  }

  Future<void> _onSubmitted(
    NewPaymentSubmitted event,
    Emitter<NewPaymentState> emit,
  ) async {
    emit(state.copyWith(status: NewPaymentStatus.submitting));
    try {
      final created = await _createPayment(event.payment);
      emit(
        state.copyWith(
          status: NewPaymentStatus.success,
          created: () => created,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: NewPaymentStatus.failure));
    }
  }
}
