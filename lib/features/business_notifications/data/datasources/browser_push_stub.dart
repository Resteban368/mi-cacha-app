import 'dart:typed_data';

import '../../domain/entities/push_message.dart';
import '../../domain/entities/push_exception.dart';
import '../../domain/entities/push_permission.dart';
import 'browser_push_contract.dart';

/// Crea la implementación de esta plataforma.
BrowserPush createBrowserPush() => BrowserPushStub();

/// Plataformas sin Web Push (Android, iOS, escritorio): no hace nada.
class BrowserPushStub implements BrowserPush {
  @override
  bool get isSupported => false;

  @override
  PushPermission get permission => PushPermission.defaultState;

  @override
  Future<PushPermission> requestPermission() async =>
      PushPermission.defaultState;

  @override
  Future<String?> currentEndpoint() async => null;

  @override
  Future<BrowserSubscription> subscribe(Uint8List applicationServerKey) =>
      throw const PushException(PushFailure.unsupported);

  @override
  Future<void> unsubscribe() async {}

  @override
  Stream<void> get newReservationMessages => const Stream.empty();

  @override
  Stream<PushMessage> get notificationMessages => const Stream.empty();
}
