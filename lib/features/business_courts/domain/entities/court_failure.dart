enum CourtFailure {
  /// El plan no permite más canchas activas (o no hay plan activo).
  planLimit,

  /// Ya existe una cancha con ese nombre en el negocio.
  duplicateName,

  /// La API rechazó los datos (horario, tarifas que se cruzan…).
  invalid,

  /// El administrador aún no registró su negocio.
  noBusiness,
  network,
  server,
}

class CourtException implements Exception {
  const CourtException(this.failure, {this.message});

  final CourtFailure failure;

  /// Mensaje del backend para el usuario (límite del plan, validaciones).
  final String? message;

  @override
  String toString() => 'CourtException($failure, $message)';
}
