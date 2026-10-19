part of 'new_reservation_bloc.dart';

sealed class NewReservationEvent extends Equatable {
  const NewReservationEvent();

  @override
  List<Object?> get props => [];
}

/// Carga canchas y métodos de pago. [courtId] elige su deporte (y se
/// resalta su tarjeta); [day] preselecciona el día.
final class NewReservationStarted extends NewReservationEvent {
  const NewReservationStarted({this.courtId, this.day, this.customer});

  final String? courtId;
  final DateTime? day;
  final Customer? customer;

  @override
  List<Object?> get props => [courtId, day, customer];
}

/// Eventos que (re)cargan los turnos; el último cancela al anterior.
sealed class NewReservationAvailabilityEvent extends NewReservationEvent {
  const NewReservationAvailabilityEvent();
}

final class NewReservationSportSelected
    extends NewReservationAvailabilityEvent {
  const NewReservationSportSelected(this.sport);

  final Sport sport;

  @override
  List<Object?> get props => [sport];
}

final class NewReservationDaySelected extends NewReservationAvailabilityEvent {
  const NewReservationDaySelected(this.day);

  final DateTime day;

  @override
  List<Object?> get props => [day];
}

final class NewReservationAvailabilityReloaded
    extends NewReservationAvailabilityEvent {
  const NewReservationAvailabilityReloaded();
}

/// "Cualquier cancha libre a esa hora": la API asigna la cancha.
final class NewReservationAnyCourtToggled extends NewReservationEvent {
  const NewReservationAnyCourtToggled(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

/// Elige el turno inicial, lo deselecciona o extiende el rango.
/// [courtId] es `null` en la grilla de "Cualquier cancha".
final class NewReservationSlotTapped extends NewReservationEvent {
  const NewReservationSlotTapped({this.courtId, required this.start});

  final String? courtId;

  /// Inicio (hora local) del turno tocado.
  final DateTime start;

  @override
  List<Object?> get props => [courtId, start];
}

/// Suma o quita otra cancha en la misma franja que la elegida.
final class NewReservationExtraCourtToggled extends NewReservationEvent {
  const NewReservationExtraCourtToggled(this.courtId);

  final String courtId;

  @override
  List<Object?> get props => [courtId];
}

/// Con "Cualquier cancha": cuántas canchas libres reservar a la vez.
final class NewReservationAnyCourtCountChanged extends NewReservationEvent {
  const NewReservationAnyCourtCountChanged(this.count);

  final int count;

  @override
  List<Object?> get props => [count];
}

final class NewReservationSlotCountChanged extends NewReservationEvent {
  const NewReservationSlotCountChanged(this.count);

  final int count;

  @override
  List<Object?> get props => [count];
}

final class NewReservationCustomerQueryChanged extends NewReservationEvent {
  const NewReservationCustomerQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Cliente existente elegido; `null` para quitarlo.
final class NewReservationCustomerSelected extends NewReservationEvent {
  const NewReservationCustomerSelected(this.customer);

  final Customer? customer;

  @override
  List<Object?> get props => [customer];
}

final class NewReservationSubmitted extends NewReservationEvent {
  const NewReservationSubmitted(this.reservation);

  final NewReservation reservation;

  @override
  List<Object?> get props => [reservation];
}
