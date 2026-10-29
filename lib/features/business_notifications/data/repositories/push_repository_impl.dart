import 'dart:convert';
import 'dart:typed_data';

import '../../domain/entities/push_exception.dart';
import '../../domain/entities/push_message.dart';
import '../../domain/entities/push_permission.dart';
import '../../domain/entities/push_snapshot.dart';
import '../../domain/repositories/push_repository.dart';
import '../datasources/browser_push_contract.dart';
import '../datasources/push_api_data_source.dart';

class PushRepositoryImpl implements PushRepository {
  const PushRepositoryImpl({
    required PushApiDataSource api,
    required BrowserPush browser,
  }) : _api = api,
       _browser = browser;

  final PushApiDataSource _api;
  final BrowserPush _browser;

  @override
  Future<PushSnapshot> status() async {
    if (!_browser.isSupported) {
      return const PushSnapshot(
        supported: false,
        available: false,
        permission: PushPermission.defaultState,
        enabled: false,
      );
    }
    final available = await _api.fetchPublicKey() != null;
    final permission = _browser.permission;
    final endpoint = await _browser.currentEndpoint();
    return PushSnapshot(
      supported: true,
      available: available,
      permission: permission,
      enabled: endpoint != null && permission == PushPermission.granted,
    );
  }

  @override
  Future<PushPermission> enable() async {
    if (!_browser.isSupported) {
      throw const PushException(PushFailure.unsupported);
    }
    // El permiso va primero: el navegador solo lo muestra mientras dura el
    // toque del usuario, y una llamada a la red antes puede hacerlo perder.
    final permission = await _browser.requestPermission();
    if (permission != PushPermission.granted) return permission;

    final key = await _api.fetchPublicKey();
    if (key == null) throw const PushException(PushFailure.unavailable);

    final subscription = await _browser.subscribe(_decodeKey(key));
    try {
      await _api.saveSubscription(subscription);
    } catch (_) {
      // Sin registro en el servidor no sirve: se deshace en el navegador.
      await _browser.unsubscribe();
      rethrow;
    }
    return permission;
  }

  @override
  Future<void> disable() async {
    final endpoint = await _browser.currentEndpoint();
    if (endpoint != null) await _api.deleteSubscription(endpoint);
    await _browser.unsubscribe();
  }

  @override
  Future<void> forget() async {
    final endpoint = await _browser.currentEndpoint();
    if (endpoint != null) await _api.forgetSubscription(endpoint);
    await _browser.unsubscribe();
  }

  @override
  Stream<void> get newReservations => _browser.newReservationMessages;

  @override
  Stream<PushMessage> get notificationsChanged => _browser.notificationMessages;

  /// Clave VAPID en base64url (sin relleno) a bytes.
  static Uint8List _decodeKey(String key) {
    final padded = key.padRight((key.length + 3) ~/ 4 * 4, '=');
    return base64Url.decode(padded);
  }
}
