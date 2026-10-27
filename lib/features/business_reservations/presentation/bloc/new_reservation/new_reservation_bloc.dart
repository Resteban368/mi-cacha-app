import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/catalogs/domain/entities/catalog_payment_method.dart';
import '../../../../../core/catalogs/domain/usecases/get_catalogs.dart';
import '../../../../../core/domain/entities/sport.dart';
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

/// Flujo de "Nueva reserva": deporte y día → turnos de sus canchas (o de
/// cualquier cancha libre) → cliente → pago.
class NewReservationBloc
    extends Bloc<NewReservationEvent, NewReservationState> {
  NewReservationBloc({
    required GetCourts getCourts,
    required GetCatalogs getCatalogs,
    required GetSportAvailability getSportAvailability,
    required SearchCustomers searchCustomers,
    required CreateReservation createReservation,
    required Clock clock,
    this.searchDebounce = const Duration(milliseconds: 250),
  }) : _getCourts = getCourts,
       _getCatalogs = getCatalogs,
       _getSportAvailability = getSportAvailability,
       _searchCustomers = searchCustomers,
       _createReservation = createReservation,
       _clock = clock,
       super(
         NewReservationState(day: _dateOnly(clock.now()), now: clock.now()),
       ) {
    on<NewReservationStarted>(_onStarted, transformer: restartable());
    // Cambiar de deporte o día cancela la carga anterior de turnos.
    on<NewReservationAvailabilityEvent>(
      _onAvailability,
      transformer: restartable(),
    );
    on<NewReservationAnyCourtToggled>(_onAnyCourtToggled);
    on<NewReservationSlotTapped>(_onSlotTapped);
    on<NewReservationSlotCountChanged>(_onSlotCountChanged);
    on<NewReservationExtraCourtToggled>(_onExtraCourtToggled);
    on<NewReservationAnyCourtCountChanged>(_onAnyCourtCountChanged);
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
  final GetSportAvailability _getSportAvailability;
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
      // Desde la agenda: el deporte de esa cancha, con su tarjeta a la vista.
      final requestedCourt = courts
          .where((c) => c.id == event.courtId && c.isBookable)
          .firstOrNull;
      final sports = [
        for (final sport in Sport.values)
          if (courts.any((c) => c.sport == sport && c.isBookable)) sport,
      ];
      final sport = requestedCourt?.sport ?? sports.firstOrNull;
      final requested = event.day == null ? null : _dateOnly(event.day!);
      final day = requested != null && !requested.isBefore(_today)
          ? requested
          : _today;
      emit(
        state.copyWith(
          load: NewReservationLoad.ready,
          courts: courts,
          paymentMethods: [...catalogs.paymentMethods.where((m) => m.active)]
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
          sport: () => sport,
          focusCourtId: () => requestedCourt?.id,
          day: day,
          customer: () => event.customer ?? state.customer,
        ),
      );
    } catch (_) {
      emit(state.copyWith(load: NewReservationLoad.failure));
      return;
    }
    if (state.sport != null) add(const NewReservationAvailabilityReloaded());
    add(const NewReservationCustomerQueryChanged(''));
  }

  Future<void> _onAvailability(
    NewReservationAvailabilityEvent event,
    Emitter<NewReservationState> emit,
  ) async {
    switch (event) {
      case NewReservationSportSelected(:final sport):
        if (sport == state.sport) return;
        emit(state.copyWith(sport: () => sport, focusCourtId: () => null));
      case NewReservationDaySelected(:final day):
        final date = _dateOnly(day);
        if (date.isBefore(_today)) return;
        emit(state.copyWith(day: date));
      case NewReservationAvailabilityReloaded():
        break;
    }
    final sport = state.sport;
    if (sport == null) return;
    // Al cambiar de deporte o de día (o recargar) se limpia la selección.
    emit(
      state.copyWith(
        availabilityLoad: AvailabilityLoad.loading,
        availability: () => null,
        selectedCourtId: () => null,
        selectedStart: () => null,
        slotCount: 1,
        extraCourtIds: const [],
        anyCourtCount: 1,
      ),
    );
    try {
      final availability = await _getSportAvailability((
        sport: sport,
        day: state.day,
      ));
      emit(
        state.copyWith(
          availabilityLoad: AvailabilityLoad.ready,
          availability: () => availability,
          now: _clock.now(),
        ),
      );
    } catch (_) {
      emit(state.copyWith(availabilityLoad: AvailabilityLoad.failure));
    }
  }

  void _onAnyCourtToggled(
    NewReservationAnyCourtToggled event,
    Emitter<NewReservationState> emit,
  ) {
    if (event.enabled == state.anyCourt) return;
    final start = state.selectedStart;
    final availability = state.availability;
    // Cambiar de modo deja una sola cancha.
    emit(state.copyWith(extraCourtIds: const [], anyCourtCount: 1));
    if (start == null || availability == null) {
      emit(state.copyWith(anyCourt: event.enabled));
      return;
    }
    if (event.enabled) {
      // Se conserva la hora; la duración se ajusta a la cancha con más turnos.
      final reach = availability.anyCourtReach(start);
      emit(
        state.copyWith(
          anyCourt: true,
          slotCount: reach == 0 ? 1 : state.slotCount.clamp(1, reach),
          selectedStart: reach == 0 ? () => null : null,
        ),
      );
      return;
    }
    // Al apagarlo queda elegida la cancha que se iba a asignar.
    final court = availability.firstFreeCourt(start, state.slotCount);
    emit(
      state.copyWith(
        anyCourt: false,
        selectedCourtId: () => court?.court.id,
        selectedStart: court == null ? () => null : null,
        slotCount: court == null ? 1 : null,
      ),
    );
  }

  void _onSlotTapped(
    NewReservationSlotTapped event,
    Emitter<NewReservationState> emit,
  ) {
    final availability = state.availability;
    if (availability == null) return;
    // Los turnos que se vencen en pantalla se ocultan al tocar otro.
    final now = _clock.now();
    emit(state.copyWith(now: now));
    final tapped = event.start;
    final current = state.selectedStart;
    final sameTarget = state.anyCourt || event.courtId == state.selectedCourtId;

    if (state.anyCourt) {
      final slots = availability.anyCourtSlots;
      // Tocar un horario dentro del alcance desde el inicio lo extiende.
      if (current != null && tapped.isAfter(current)) {
        final from = slots.indexWhere((s) => s.start == current);
        final to = slots.indexWhere((s) => s.start == tapped);
        final count = to - from + 1;
        if (from >= 0 &&
            count <= availability.reachFor(current, state.anyCourtCount)) {
          emit(state.copyWith(slotCount: count));
          return;
        }
      }
      if (tapped == current) {
        emit(state.copyWith(selectedStart: () => null, slotCount: 1));
        return;
      }
      final slot = slots.where((s) => s.start == tapped).firstOrNull;
      if (slot == null || slot.isExpiredAt(now)) return;
      // Si a esa hora hay menos canchas libres que las pedidas, se ajusta.
      final free = availability.courtsFreeAt(tapped, 1).length;
      if (free == 0) return;
      final courts = state.anyCourtCount.clamp(1, free);
      final max = availability.reachFor(tapped, courts);
      emit(
        state.copyWith(
          selectedStart: () => tapped,
          anyCourtCount: courts,
          slotCount: state.slotCount.clamp(1, max),
        ),
      );
      return;
    }

    final court = availability.courtById(event.courtId);
    if (court == null) return;
    if (sameTarget && current != null && tapped.isAfter(current)) {
      // Un turno libre seguido de la misma cancha extiende el rango.
      // El alcance es el de todas las canchas elegidas.
      final from = court.indexOf(current);
      final to = court.indexOf(tapped);
      final reach = state.maxSlotCount;
      if (from >= 0 && to < from + reach) {
        emit(state.copyWith(slotCount: to - from + 1));
        return;
      }
    }
    if (sameTarget && tapped == current) {
      emit(
        state.copyWith(
          selectedCourtId: () => null,
          selectedStart: () => null,
          slotCount: 1,
          extraCourtIds: const [],
        ),
      );
      return;
    }
    final index = court.indexOf(tapped);
    if (index < 0 || court.slots[index].isExpiredAt(now)) return;
    final max = court.consecutiveFrom(index, availability.maxSlots);
    if (max == 0) return;
    emit(
      state.copyWith(
        selectedCourtId: () => court.court.id,
        selectedStart: () => tapped,
        slotCount: state.slotCount.clamp(1, max),
        extraCourtIds: const [],
      ),
    );
  }

  void _onExtraCourtToggled(
    NewReservationExtraCourtToggled event,
    Emitter<NewReservationState> emit,
  ) {
    final extras = state.extraCourtIds;
    if (extras.contains(event.courtId)) {
      emit(
        state.copyWith(
          extraCourtIds: [
            for (final id in extras)
              if (id != event.courtId) id,
          ],
        ),
      );
      return;
    }
    if (!state.addableCourts.any((c) => c.court.id == event.courtId)) return;
    emit(state.copyWith(extraCourtIds: [...extras, event.courtId]));
  }

  void _onAnyCourtCountChanged(
    NewReservationAnyCourtCountChanged event,
    Emitter<NewReservationState> emit,
  ) {
    final start = state.selectedStart;
    final availability = state.availability;
    if (!state.anyCourt || start == null || availability == null) return;
    final free = availability.courtsFreeAt(start, 1).length;
    final courts = event.count.clamp(
      1,
      free.clamp(1, NewReservation.maxCourts),
    );
    final max = availability.reachFor(start, courts);
    if (max == 0) return;
    emit(
      state.copyWith(
        anyCourtCount: courts,
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
      subtotal: state.lowestSubtotal,
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
      // Otro tomó el turno (o todas las canchas), o se venció mientras se
      // elegía: se recargan los turnos para elegir de nuevo.
      if (error.failure
          case ReservationFailure.slotTaken || ReservationFailure.slotExpired) {
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
