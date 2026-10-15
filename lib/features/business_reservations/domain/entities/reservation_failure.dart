enum ReservationFailure {
  /// 409: el turno lo tomó otra reserva mientras se elegía.
  slotTaken,

  /// 409: la cancha está desactivada o le faltan fotos.
  courtNotBookable,

  /// 409: el teléfono y la cédula son de clientes distintos.
  customerConflict,

  /// 409: solo se pueden cancelar reservas confirmadas.
  notCancellable,

  /// 403 SUBSCRIPTION_INACTIVE: el negocio está en solo lectura.
  subscriptionInactive,

  /// 400: algún dato no cumple las reglas (el mensaje lo explica).
  invalid,

  /// 404: cancha, cliente o reserva inexistentes.
  notFound,
  network,
  server,
}

class ReservationException implements Exception {
  const ReservationException(this.failure, {this.message});

  final ReservationFailure failure;

  /// Mensaje del backend para el usuario (las listas se unen por línea).
  final String? message;

  @override
  String toString() => 'ReservationException($failure, $message)';
}
