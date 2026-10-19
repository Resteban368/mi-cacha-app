/// Motivos por los que no se pudo activar o desactivar el aviso.
enum PushFailure { unsupported, unavailable, denied, network, server }

class PushException implements Exception {
  const PushException(this.failure);

  final PushFailure failure;

  @override
  String toString() => 'PushException($failure)';
}
