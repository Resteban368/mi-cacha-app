part of 'business_reservations_bloc.dart';

sealed class BusinessReservationsEvent extends Equatable {
  const BusinessReservationsEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar las reservas de un día (por defecto, hoy).
final class ReservationsRequested extends BusinessReservationsEvent {
  const ReservationsRequested([this.day]);

  final DateTime? day;

  @override
  List<Object?> get props => [day];
}

/// Pull-to-refresh: recarga el día actual sin ocultar el listado.
final class ReservationsRefreshed extends BusinessReservationsEvent {
  const ReservationsRefreshed();
}

/// Activa un filtro; si ya estaba activo, lo quita (muestra todas).
final class ReservationsFilterToggled extends BusinessReservationsEvent {
  const ReservationsFilterToggled(this.filter);

  final ReservationFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// Tick del reloj: reevalúa qué reservas están en juego.
final class ReservationsClockTicked extends BusinessReservationsEvent {
  const ReservationsClockTicked();
}
