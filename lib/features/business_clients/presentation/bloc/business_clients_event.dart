import 'package:equatable/equatable.dart';

import '../../domain/entities/client_filter.dart';
import '../../domain/entities/customer_payload.dart';
import '../../domain/entities/customer_query.dart';

sealed class BusinessClientsEvent extends Equatable {
  const BusinessClientsEvent();

  @override
  List<Object?> get props => [];
}

/// Inicia la carga de clientes con una consulta inicial (o por defecto).
final class BusinessClientsStarted extends BusinessClientsEvent {
  const BusinessClientsStarted({this.query = const CustomerQuery()});

  final CustomerQuery query;

  @override
  List<Object?> get props => [query];
}

/// Cambia el término de búsqueda de clientes (con debounce).
final class BusinessClientsSearchChanged extends BusinessClientsEvent {
  const BusinessClientsSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

/// Cambia el segmento o filtro rápido (Todos, VIP, Con saldo pendiente, Nuevos).
final class BusinessClientsSegmentChanged extends BusinessClientsEvent {
  const BusinessClientsSegmentChanged(this.segment);

  final ClientFilterType segment;

  @override
  List<Object?> get props => [segment];
}

/// Cambia el criterio de ordenamiento.
final class BusinessClientsSortChanged extends BusinessClientsEvent {
  const BusinessClientsSortChanged(this.sort);

  final ClientSortBy sort;

  @override
  List<Object?> get props => [sort];
}

/// Cambia la página actual en la paginación.
final class BusinessClientsPageChanged extends BusinessClientsEvent {
  const BusinessClientsPageChanged(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

/// Recarga los clientes con la consulta actual.
final class BusinessClientsRefreshed extends BusinessClientsEvent {
  const BusinessClientsRefreshed();
}

/// Solicita crear un nuevo cliente.
final class BusinessClientsCustomerCreated extends BusinessClientsEvent {
  const BusinessClientsCustomerCreated(this.payload);

  final CustomerPayload payload;

  @override
  List<Object?> get props => [payload];
}

/// Solicita actualizar un cliente existente.
final class BusinessClientsCustomerUpdated extends BusinessClientsEvent {
  const BusinessClientsCustomerUpdated({
    required this.id,
    required this.payload,
  });

  final String id;
  final CustomerPayload payload;

  @override
  List<Object?> get props => [id, payload];
}
