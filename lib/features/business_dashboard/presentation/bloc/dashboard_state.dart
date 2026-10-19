part of 'dashboard_bloc.dart';

enum DashboardStatus { initial, loading, success, failure }

final class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.filter = const DashboardFilter(),
    this.dashboard,
    this.courts = const [],
    this.failure,
    this.failureMessage,
  });

  final DashboardStatus status;
  final DashboardFilter filter;

  /// Último resultado (se conserva mientras se recarga con otro filtro).
  final BusinessDashboard? dashboard;

  /// Canchas del negocio, para filtrar por deporte o cancha.
  final List<Court> courts;
  final DashboardFailure? failure;
  final String? failureMessage;

  bool get isLoading =>
      status == DashboardStatus.initial || status == DashboardStatus.loading;

  /// Deportes con canchas, en orden fijo.
  List<Sport> get sports => [
    for (final sport in Sport.values)
      if (courts.any((c) => c.sport == sport)) sport,
  ];

  /// Canchas que se pueden elegir con el deporte del filtro.
  List<Court> get filterCourts => [
    for (final court in courts)
      if (filter.sport == null || court.sport == filter.sport) court,
  ];

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardFilter? filter,
    BusinessDashboard? Function()? dashboard,
    List<Court>? courts,
    DashboardFailure? Function()? failure,
    String? Function()? failureMessage,
  }) => DashboardState(
    status: status ?? this.status,
    filter: filter ?? this.filter,
    dashboard: dashboard != null ? dashboard() : this.dashboard,
    courts: courts ?? this.courts,
    failure: failure != null ? failure() : this.failure,
    failureMessage: failureMessage != null
        ? failureMessage()
        : this.failureMessage,
  );

  @override
  List<Object?> get props => [
    status,
    filter,
    dashboard,
    courts,
    failure,
    failureMessage,
  ];
}
