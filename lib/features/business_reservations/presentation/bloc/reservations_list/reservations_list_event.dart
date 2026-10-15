part of 'reservations_list_bloc.dart';

sealed class ReservationsListEvent extends Equatable {
  const ReservationsListEvent();

  @override
  List<Object?> get props => [];
}

/// Eventos que rehacen la lista desde la página 1 (gana el último).
sealed class ReservationsListQueryEvent extends ReservationsListEvent {
  const ReservationsListQueryEvent();
}

/// Carga inicial (también las canchas del filtro).
final class ReservationsListStarted extends ReservationsListQueryEvent {
  const ReservationsListStarted([this.query = const ReservationQuery()]);

  final ReservationQuery query;

  @override
  List<Object?> get props => [query];
}

/// Nuevos filtros. [debounce] al escribir en la búsqueda.
final class ReservationsListQueryChanged extends ReservationsListQueryEvent {
  const ReservationsListQueryChanged(this.query, {this.debounce = false});

  final ReservationQuery query;
  final bool debounce;

  @override
  List<Object?> get props => [query, debounce];
}

/// Recarga con los mismos filtros (deslizar o tras cancelar una reserva).
final class ReservationsListRefreshed extends ReservationsListQueryEvent {
  const ReservationsListRefreshed({this.done});

  /// Se completa al terminar, para cerrar el indicador de "deslizar".
  final Completer<void>? done;
}

final class ReservationsListMoreRequested extends ReservationsListEvent {
  const ReservationsListMoreRequested();
}
