import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/catalogs/domain/entities/catalog_payment_method.dart';
import '../../../../../core/catalogs/domain/usecases/get_catalogs.dart';
import '../../../../../core/usecase/usecase.dart';
import '../../../../../core/utils/clock.dart';
import '../../../../business_courts/domain/entities/court.dart';
import '../../../../business_courts/domain/usecases/get_courts.dart';
import '../../../domain/entities/availability.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/new_reservation.dart';
import '../../../domain/entities/reservation.dart';
import '../../../domain/entities/reservation_failure.dart';
import '../../../domain/usecases/booking_usecases.dart';

part 'new_reservation_event.dart';
part 'new_reservation_state.dart';

/// Flujo de "Nueva reserva": cancha y día → turnos → cliente → pago.
class NewReservationBloc
    extends Bloc<NewReservationEvent, NewReservationState> {
  NewReservationBloc({
    required GetCourts getCourts,
    required GetCatalogs getCatalogs,
    required GetAvailability getAvailability,
    required SearchCustomers searchCustomers,
    required CreateReservation createReservation,
    required Clock clock,
    this.searchDebounce = const Duration(milliseconds: 300),
  }) : _getCourts = getCourts,
       _getCatalogs = getCatalogs,
       _getAvailability = getAvailability,
       _searchCustomers = searchCustomers,
       _createReservation = createReservation,
       _clock = clock,
       super(NewReservationState(day: _dateOnly(clock.now()))) {
    on<NewReservationStarted>(_onStarted, transformer: restartable());
    // Cambiar de cancha o día cancela la carga anterior de turnos.
    on<NewReservationAvailabilityEvent>(
      _onAvailability,
      transformer: restartable(),
    );
    on<NewReservationSlotTapped>(_onSlotTapped);
    on<NewReservationSlotCountChanged>(_onSlotCountChanged);
    // Gana la última búsqueda (con espera mientras se escribe).
    on<NewReservationCustomerQueryChanged>(
      _onCustomerQuery,
      transformer: restartable(),
    );
    on<NewReservationCustomerSelected>(_onCustomerSelected);
    // Un doble toque en "Confirmar" no crea dos reservas.
    on<NewReservationSubmitted>(_onSubmitted, transformer: droppable());
  }

  final GetCourts _getCourts;
  final GetCatalogs _getCatalogs;
  final GetAvailability _getAvailability;
  final SearchCustomers _searchCustomers;
  final CreateReservation _createReservation;
  final Clock _clock;
  final Duration searchDebounce;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _today => _dateOnly(_clock.now());

  Future<void> _onStarted(
    NewReservationStarted event,
    Emitter<NewReservationState> emit,
  ) async {
    emit(state.copyWith(load: NewReservationLoad.loading));
    try {
      final (courts, catalogs) = await (
        _getCourts(const NoParams()),
        _getCatalogs(const NoParams()),
      ).wait;
      final bookable = courts.where((c) => c.isBookable);
      final court =
          courts
              .where((c) => c.id == event.courtId && c.isBookable)
              .firstOrNull ??
          bookable.firstOrNull;
      final requested = event.day == null ? null : _dateOnly(event.day!);
      final day = requested != null && !requested.isBefore(_today)
          ? requested
          : _today;
      emit(
        state.copyWith(
          load: NewReservationLoad.ready,
          courts: [...bookable, ...courts.where((c) => !c.isBookable)],
          paymentMethods: [...catalogs.paymentMethods.where((m) => m.active)]
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
          court: () => court,
          day: day,
          customer: () => event.customer ?? state.customer,
        ),
      );
    } catch (_) {
      emit(state.copyWith(load: NewReservationLoad.failure));
      return;
    }
    if (state.court != null) add(const NewReservationAvailabilityReloaded());
    add(const NewReservationCustomerQueryChanged(''));
  }

  Future<void> _onAvailability(
    NewReservationAvailabilityEvent event,
    Emitter<NewReservationState> emit,
  ) async {
    switch (event) {
      case NewReservationCourtSelected(:final court):
        if (!court.isBookable) return;
        emit(state.copyWith(court: () => court));
      case NewReservationDaySelected(:final day):
        final date = _dateOnly(day);
        if (date.isBefore(_today)) return;
        emit(state.copyWith(day: date));
      case NewReservationAvailabilityReloaded():
        break;
    }
    final court = state.court;
    if (court == null) return;
    emit(
      state.copyWith(
        availabilityLoad: AvailabilityLoad.loading,
        availability: () => null,
        startIndex: () => null,
        slotCount: 1,
      ),
    );
    try {
      final availability = await _getAvailability((
        courtId: court.id,
        day: state.day,
      ));
      emit(
        state.copyWith(
          availabilityLoad: AvailabilityLoad.ready,
          availability: () => availability,
        ),
      );
    } catch (_) {
      emit(state.copyWith(availabilityLoad: AvailabilityLoad.failure));
    }
  }

  void _onSlotTapped(
    NewReservationSlotTapped event,
    Emitter<NewReservationState> emit,
  ) {
    final availability = state.availability;
    if (availability == null) return;
    final index = event.index;
    final start = state.startIndex;
    // Tocar un turno dentro del bloque libre que sigue al inicio lo extiende.
    if (start != null && index > start) {
      final reach = availability.consecutiveFrom(start);
      if (index < start + reach) {
        emit(state.copyWith(slotCount: index - start + 1));
        return;
      }
    }
    if (index == start) {
      emit(state.copyWith(startIndex: () => null, slotCount: 1));
      return;
    }
    final max = availability.consecutiveFrom(index);
    if (max == 0) return;
    emit(
      state.copyWith(
        startIndex: () => index,
        slotCount: state.slotCount.clamp(1, max),
      ),
    );
  }

  void _onSlotCountChanged(
    NewReservationSlotCountChanged event,
    Emitter<NewReservationState> emit,
  ) {
    final max = state.maxSlotCount;
    if (max == 0) return;
    emit(state.copyWith(slotCount: event.count.clamp(1, max)));
  }

  Future<void> _onCustomerQuery(
    NewReservationCustomerQueryChanged event,
    Emitter<NewReservationState> emit,
  ) async {
    emit(
      state.copyWith(
        customerQuery: event.query,
        customerSearch: CustomerSearchStatus.loading,
      ),
    );
    if (event.query.isNotEmpty) {
      await Future<void>.delayed(searchDebounce);
      if (emit.isDone) return;
    }
    try {
      final results = await _searchCustomers(event.query);
      emit(
        state.copyWith(
          customerResults: results,
          customerSearch: CustomerSearchStatus.ready,
        ),
      );
    } catch (_) {
      emit(state.copyWith(customerSearch: CustomerSearchStatus.failure));
    }
  }

  void _onCustomerSelected(
    NewReservationCustomerSelected event,
    Emitter<NewReservationState> emit,
  ) => emit(state.copyWith(customer: () => event.customer));

  Future<void> _onSubmitted(
    NewReservationSubmitted event,
    Emitter<NewReservationState> emit,
  ) async {
    final error = CreateReservation.validate(
      event.reservation,
      subtotal: state.subtotal,
    );
    if (error != null) {
      emit(
        state.copyWith(
          submit: NewReservationSubmit.failure,
          failure: () => ReservationFailure.invalid,
          failureMessage: () => error,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        submit: NewReservationSubmit.submitting,
        failure: () => null,
        failureMessage: () => null,
      ),
    );
    try {
      final created = await _createReservation(event.reservation);
      emit(
        state.copyWith(
          submit: NewReservationSubmit.success,
          created: () => created,
        ),
      );
    } on ReservationException catch (error) {
      emit(
        state.copyWith(
          submit: NewReservationSubmit.failure,
          failure: () => error.failure,
          failureMessage: () => error.message,
        ),
      );
      // Otro tomó el turno: se recargan los turnos para elegir de nuevo.
      if (error.failure == ReservationFailure.slotTaken) {
        add(const NewReservationAvailabilityReloaded());
      }
    } catch (_) {
      emit(
        state.copyWith(
          submit: NewReservationSubmit.failure,
          failure: () => ReservationFailure.server,
          failureMessage: () => null,
        ),
      );
    }
  }
}
