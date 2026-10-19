enum DashboardFailure {
  /// 400: el período o los filtros no son válidos (el mensaje lo explica).
  invalid,

  /// 404: el dashboard todavía no está disponible en el servidor.
  notAvailable,
  network,
  server,
}

class DashboardException implements Exception {
  const DashboardException(this.failure, {this.message});

  final DashboardFailure failure;
  final String? message;

  @override
  String toString() => 'DashboardException($failure, $message)';
}
