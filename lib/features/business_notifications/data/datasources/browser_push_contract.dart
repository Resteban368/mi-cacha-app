import 'dart:typed_data';

import '../../domain/entities/push_permission.dart';

/// Suscripción del navegador, tal como la espera el servidor.
class BrowserSubscription {
  const BrowserSubscription({
    required this.endpoint,
    required this.p256dh,
    required this.auth,
  });

  final String endpoint;
  final String p256dh;
  final String auth;
}

/// Acceso al navegador para Web Push. Cada plataforma tiene su versión.
abstract interface class BrowserPush {
  /// `true` solo en web con Push, Notification y Service Worker.
  bool get isSupported;

  /// Permiso actual, sin pedirlo.
  PushPermission get permission;

  /// Pide el permiso. Solo debe llamarse tras un gesto del usuario.
  Future<PushPermission> requestPermission();

  /// Endpoint de la suscripción activa, o `null` si no hay.
  Future<String?> currentEndpoint();

  /// Suscribe el navegador con la clave pública VAPID.
  Future<BrowserSubscription> subscribe(Uint8List applicationServerKey);

  /// Cancela la suscripción activa, si existe.
  Future<void> unsubscribe();

  /// Mensajes del Service Worker que indican una reserva nueva.
  Stream<void> get newReservationMessages;

  /// Cualquier aviso que llega con la app abierta (reservas y avisos del
  /// administrador): sirve para refrescar la bandeja.
  Stream<void> get notificationMessages;
}
