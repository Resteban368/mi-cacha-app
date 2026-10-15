import 'package:flutter/foundation.dart';

import 'session.dart';
import 'session_storage.dart';

/// Fuente única de la sesión actual: la guarda, la restaura al abrir la app
/// y la cierra (logout o 401). El router escucha sus cambios para proteger
/// las rutas del negocio.
class SessionManager extends ChangeNotifier {
  SessionManager(this._storage);

  final SessionStorage _storage;

  Session? _session;
  Future<Session?>? _restoring;
  bool _expired = false;

  Session? get current => _session;
  String? get accessToken => _session?.accessToken;
  bool get isBusinessAdmin => _session?.isBusinessAdmin ?? false;

  /// Lee la sesión guardada una sola vez (llamadas concurrentes comparten
  /// la misma lectura). Si el storage falla, se trata como sin sesión.
  Future<Session?> restore() => _restoring ??= _read();

  Future<Session?> _read() async {
    try {
      _session = await _storage.read();
    } catch (_) {
      _session = null;
    }
    return _session;
  }

  Future<void> start(Session session) async {
    await _storage.write(session);
    _session = session;
    _restoring = Future.value(session);
    _expired = false;
    notifyListeners();
  }

  /// Cierre de sesión voluntario.
  Future<void> end() async {
    _session = null;
    _restoring = Future.value();
    try {
      await _storage.clear();
    } catch (_) {
      // Aunque falle el borrado, en memoria ya no hay sesión.
    }
    notifyListeners();
  }

  /// La API respondió 401 con el token actual: la sesión venció.
  Future<void> expire() async {
    if (_session == null) return;
    _expired = true;
    await end();
  }

  /// `true` una sola vez después de [expire], para avisar en el login.
  bool consumeExpired() {
    final expired = _expired;
    _expired = false;
    return expired;
  }
}
