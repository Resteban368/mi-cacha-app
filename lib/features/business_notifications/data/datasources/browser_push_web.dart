import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../../domain/entities/push_exception.dart';
import '../../domain/entities/push_permission.dart';
import 'browser_push_contract.dart';

/// Crea la implementación web.
BrowserPush createBrowserPush() => BrowserPushWeb();

/// Web Push con el navegador (package:web). El Service Worker vive en
/// /push/sw.js con alcance /push/, así no choca con el de Flutter.
class BrowserPushWeb implements BrowserPush {
  BrowserPushWeb() {
    if (isSupported) {
      web.window.navigator.serviceWorker.addEventListener(
        'message',
        ((web.Event event) {
          final data = (event as web.MessageEvent).data;
          final type = (data as JSObject?)?.getProperty<JSString?>('type'.toJS);
          if (type == null) return;
          _anyMessages.add(null);
          if (type.toDart == 'NEW_RESERVATION') {
            _playChime();
            _messages.add(null);
          }
        }).toJS,
      );
    }
  }

  static const _scriptUrl = '/push/sw.js';
  static const _scope = '/push/';

  final _messages = StreamController<void>.broadcast();
  final _anyMessages = StreamController<void>.broadcast();
  web.AudioContext? _audio;

  /// Dos tonos cortos para avisar con la app abierta. El navegador puede
  /// bloquear el audio si el usuario no ha tocado nada en la página.
  void _playChime() {
    try {
      final ctx = _audio ??= web.AudioContext();
      if (ctx.state == 'suspended') ctx.resume();
      final now = ctx.currentTime;
      for (final (i, freq) in [880.0, 1175.0].indexed) {
        final start = now + i * 0.18;
        final osc = ctx.createOscillator()..type = 'sine';
        final gain = ctx.createGain();
        osc.frequency.value = freq;
        osc.connect(gain);
        gain.connect(ctx.destination);
        gain.gain
          ..setValueAtTime(0.0001, start)
          ..exponentialRampToValueAtTime(0.25, start + 0.02)
          ..exponentialRampToValueAtTime(0.0001, start + 0.35);
        osc.start(start);
        osc.stop(start + 0.4);
      }
    } catch (_) {
      // Sin audio disponible: el aviso visual sigue funcionando.
    }
  }

  @override
  bool get isSupported =>
      web.window.isSecureContext &&
      globalContext.hasProperty('PushManager'.toJS).toDart &&
      globalContext.hasProperty('Notification'.toJS).toDart &&
      web.window.navigator.hasProperty('serviceWorker'.toJS).toDart;

  @override
  PushPermission get permission =>
      PushPermission.fromBrowser(web.Notification.permission);

  @override
  Future<PushPermission> requestPermission() async {
    final result = await web.Notification.requestPermission().toDart;
    return PushPermission.fromBrowser(result.toDart);
  }

  /// Registra el Service Worker y espera a que esté activo: sin un worker
  /// activo, Safari y Chrome rechazan la suscripción.
  Future<web.ServiceWorkerRegistration> _register() async {
    final registration = await web.window.navigator.serviceWorker
        .register(_scriptUrl.toJS, web.RegistrationOptions(scope: _scope))
        .toDart;
    final pending = registration.installing ?? registration.waiting;
    if (registration.active == null && pending != null) {
      final activated = Completer<void>();
      void check() {
        if (pending.state == 'activated' && !activated.isCompleted) {
          activated.complete();
        }
      }

      pending.addEventListener('statechange', ((web.Event _) => check()).toJS);
      check();
      await activated.future.timeout(const Duration(seconds: 10));
    }
    return registration;
  }

  Future<web.PushSubscription?> _existing() async {
    final registration = await web.window.navigator.serviceWorker
        .getRegistration(_scope)
        .toDart;
    if (registration == null) return null;
    return registration.pushManager.getSubscription().toDart;
  }

  @override
  Future<String?> currentEndpoint() async => (await _existing())?.endpoint;

  @override
  Future<BrowserSubscription> subscribe(Uint8List applicationServerKey) async {
    if (!isSupported) throw const PushException(PushFailure.unsupported);
    final registration = await _register();
    final subscription = await registration.pushManager
        .subscribe(
          web.PushSubscriptionOptionsInit(
            userVisibleOnly: true,
            applicationServerKey: applicationServerKey.toJS,
          ),
        )
        .toDart;
    final json = subscription.toJSON();
    final keys = json.keys;
    return BrowserSubscription(
      endpoint: subscription.endpoint,
      p256dh: keys.getProperty<JSString>('p256dh'.toJS).toDart,
      auth: keys.getProperty<JSString>('auth'.toJS).toDart,
    );
  }

  @override
  Future<void> unsubscribe() async {
    final subscription = await _existing();
    if (subscription != null) await subscription.unsubscribe().toDart;
  }

  @override
  Stream<void> get newReservationMessages => _messages.stream;

  @override
  Stream<void> get notificationMessages => _anyMessages.stream;
}
