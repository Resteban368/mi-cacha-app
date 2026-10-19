import 'package:equatable/equatable.dart';

import 'push_permission.dart';

/// Estado del aviso en este navegador y en el servidor.
class PushSnapshot extends Equatable {
  const PushSnapshot({
    required this.supported,
    required this.available,
    required this.permission,
    required this.enabled,
  });

  /// El navegador soporta Web Push (solo web).
  final bool supported;

  /// El servidor tiene la clave VAPID configurada.
  final bool available;
  final PushPermission permission;

  /// Hay una suscripción activa en este navegador.
  final bool enabled;

  @override
  List<Object?> get props => [supported, available, permission, enabled];
}
