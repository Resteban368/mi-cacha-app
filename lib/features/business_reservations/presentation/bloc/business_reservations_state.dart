part of 'business_reservations_bloc.dart';

enum ReservationsStatus { initial, loading, success, failure }

final class BusinessReservationsState extends Equatable {
  const BusinessReservationsState({
    required this.day,
    required this.now,
    this.status = ReservationsStatus.initial,
    this.reservations = const [],
    this.filter,
    this.isRefreshing = false,
    this.courts = const [],
  });

  final ReservationsStatus status;
  final DateTime day;
  final DateTime now;
  final List<Reservation> reservations;

  /// `null` = todas.
  final ReservationFilter? filter;
  final bool isRefreshing;

  /// Canchas del negocio con su horario (para la ocupación por cancha).
  final List<Court> courts;

  DayAgenda get agenda =>
      DayAgenda(day: day, now: now, reservations: reservations);

  BusinessReservationsState copyWith({
    ReservationsStatus? status,
    DateTime? day,
    DateTime? now,
    List<Reservation>? reservations,
    ReservationFilter? Function()? filter,
    bool? isRefreshing,
    List<Court>? courts,
  }) => BusinessReservationsState(
    status: status ?? this.status,
    day: day ?? this.day,
    now: now ?? this.now,
    reservations: reservations ?? this.reservations,
    filter: filter != null ? filter() : this.filter,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    courts: courts ?? this.courts,
  );

  @override
  List<Object?> get props => [
    status,
    day,
    now,
    reservations,
    filter,
    isRefreshing,
    courts,
  ];
}
