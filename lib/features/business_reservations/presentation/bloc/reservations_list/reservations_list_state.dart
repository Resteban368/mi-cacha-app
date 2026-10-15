part of 'reservations_list_bloc.dart';

enum ReservationsListStatus { loading, ready, failure }

final class ReservationsListState extends Equatable {
  const ReservationsListState({
    this.status = ReservationsListStatus.loading,
    this.query = const ReservationQuery(),
    this.items = const [],
    this.total = 0,
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.courts = const [],
  });

  final ReservationsListStatus status;
  final ReservationQuery query;
  final List<Reservation> items;

  /// Total con los filtros actuales (no solo las cargadas).
  final int total;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final bool loadMoreFailed;

  /// Canchas del negocio, para filtrar por cancha.
  final List<Court> courts;

  ReservationsListState copyWith({
    ReservationsListStatus? status,
    ReservationQuery? query,
    List<Reservation>? items,
    int? total,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    bool? loadMoreFailed,
    List<Court>? courts,
  }) => ReservationsListState(
    status: status ?? this.status,
    query: query ?? this.query,
    items: items ?? this.items,
    total: total ?? this.total,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    courts: courts ?? this.courts,
  );

  @override
  List<Object?> get props => [
    status,
    query,
    items,
    total,
    page,
    hasMore,
    loadingMore,
    loadMoreFailed,
    courts,
  ];
}
