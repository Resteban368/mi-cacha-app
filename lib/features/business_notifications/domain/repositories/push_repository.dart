import '../entities/push_permission.dart';
import '../entities/push_snapshot.dart';

abstract interface class PushRepository {
  /// Estado actual del aviso (no pide permisos).
  Future<PushSnapshot> status();

  /// Pide permiso y suscribe el navegador. Devuelve el permiso final.
  Future<PushPermission> enable();

  /// Quita la suscripción en el servidor y en el navegador.
  Future<void> disable();

  /// Se emite cuando llega una reserva nueva mientras la app está abierta.
  Stream<void> get newReservations;
}
