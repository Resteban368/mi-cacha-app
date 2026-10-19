part of 'dashboard_bloc.dart';

/// Eventos que (re)cargan el dashboard; el último cancela al anterior.
sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Primera carga: métricas de hoy y las canchas para los filtros.
final class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

/// Cambió el período, el deporte o la cancha.
final class DashboardFilterChanged extends DashboardEvent {
  const DashboardFilterChanged(this.filter);

  final DashboardFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// Recargar con los mismos filtros (deslizar hacia abajo o reintentar).
final class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
}
