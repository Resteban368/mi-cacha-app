import 'package:equatable/equatable.dart';

import 'reservation.dart';

/// Filtros del listado de todas las reservas (combinables entre sí).
class ReservationQuery extends Equatable {
  const ReservationQuery({
    this.search = '',
    this.status,
    this.courtId,
    this.customerId,
    this.from,
    this.to,
  });

  /// Nombre, teléfono o cédula del cliente.
  final String search;
  final ReservationStatus? status;
  final String? courtId;
  final String? customerId;

  /// Días locales, inclusive.
  final DateTime? from;
  final DateTime? to;

  bool get hasFilters =>
      search.trim().isNotEmpty ||
      status != null ||
      courtId != null ||
      customerId != null ||
      from != null ||
      to != null;

  ReservationQuery copyWith({
    String? search,
    ReservationStatus? Function()? status,
    String? Function()? courtId,
    String? Function()? customerId,
    DateTime? Function()? from,
    DateTime? Function()? to,
  }) => ReservationQuery(
    search: search ?? this.search,
    status: status != null ? status() : this.status,
    courtId: courtId != null ? courtId() : this.courtId,
    customerId: customerId != null ? customerId() : this.customerId,
    from: from != null ? from() : this.from,
    to: to != null ? to() : this.to,
  );

  @override
  List<Object?> get props => [search, status, courtId, customerId, from, to];
}

/// Una página del listado (de la más reciente a la más antigua).
class ReservationPage extends Equatable {
  const ReservationPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  static const defaultPageSize = 20;

  final List<Reservation> items;

  /// Total de reservas que cumplen los filtros.
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < total;

  @override
  List<Object?> get props => [items, total, page, pageSize];
}
