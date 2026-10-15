part of 'new_reservation_bloc.dart';

sealed class NewReservationEvent extends Equatable {
  const NewReservationEvent();

  @override
  List<Object?> get props => [];
}

/// Carga canchas y métodos de pago. [courtId] y [day] preseleccionan.
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

final class NewReservationCourtSelected
    extends NewReservationAvailabilityEvent {
  const NewReservationCourtSelected(this.court);

  final Court court;

  @override
  List<Object?> get props => [court];
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

/// Elige el turno inicial, lo deselecciona o extiende el rango.
final class NewReservationSlotTapped extends NewReservationEvent {
  const NewReservationSlotTapped(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
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
