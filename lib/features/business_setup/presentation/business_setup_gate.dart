import 'package:flutter/widgets.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/entities/setup_progress.dart';
import '../domain/usecases/get_setup_progress.dart';

/// Rutas del panel que se pueden abrir en cada paso de la configuración.
extension SetupStepRoutes on SetupStep {
  /// Pantalla donde se completa el paso (o Reservas si ya terminó).
  String get path => switch (this) {
    SetupStep.business => AppRoutes.businessProfile,
    SetupStep.court => AppRoutes.businessCourts,
    SetupStep.done => AppRoutes.businessReservations,
  };

  /// Mi cuenta siempre queda abierta (plan, contraseña, cerrar sesión).
  bool allows(String location) => switch (this) {
    SetupStep.done => true,
    SetupStep.business =>
      location.startsWith(AppRoutes.businessProfile) ||
          location.startsWith(AppRoutes.businessSettings),
    SetupStep.court =>
      SetupStep.business.allows(location) ||
          location.startsWith(AppRoutes.businessCourts),
  };
}

/// Recuerda en qué paso de la configuración va el negocio de la sesión
/// actual. El router lo consulta para bloquear el panel hasta completarla.
///
/// Se pide a la API una vez por sesión; las pantallas llaman a [refresh]
/// después de guardar. Si la consulta falla (sin conexión) no se bloquea
/// nada y se reintenta en la siguiente navegación.
class BusinessSetupGate extends ChangeNotifier {
  BusinessSetupGate(this._getProgress, this._session);

  final GetSetupProgress _getProgress;
  final SessionManager _session;

  String? _token;
  SetupProgress? _progress;
  Future<SetupProgress?>? _loading;
  String? _pendingTarget;

  /// Último progreso conocido de la sesión actual; `null` si no se sabe.
  SetupProgress? get progress =>
      _token == _session.accessToken ? _progress : null;

  Future<SetupProgress?> load() {
    final token = _session.accessToken;
    if (token != _token) {
      // Otra sesión (login, logout): se olvida lo anterior.
      _token = token;
      _progress = null;
      _loading = null;
      _pendingTarget = null;
    }
    if (_progress case final progress?) return Future.value(progress);
    // Se suelta al terminar (después de guardarlo) para reintentar si falló.
    return _loading ??= _fetch(token).whenComplete(() {
      if (token == _token) _loading = null;
    });
  }

  Future<SetupProgress?> _fetch(String? token) async {
    try {
      final progress = await _getProgress(const NoParams());
      if (token == _token) _progress = progress;
      return progress;
    } catch (_) {
      return null;
    }
  }

  /// Vuelve a consultar tras un cambio. Si el negocio avanzó de paso, la
  /// próxima evaluación del router lleva a la pantalla del paso nuevo.
  Future<void> refresh() async {
    final before = progress?.step;
    _progress = null;
    _loading = null;
    final after = (await load())?.step;
    if (before != null && after != null && after.index > before.index) {
      _pendingTarget = after.path;
    }
    notifyListeners();
  }

  /// Pantalla a la que hay que ir por un avance de paso; una sola vez.
  String? consumePendingTarget() {
    final target = _pendingTarget;
    _pendingTarget = null;
    return target;
  }
}

/// Expone el [BusinessSetupGate] a las pantallas del panel para que avisen
/// cuando guardan algo que puede completar la configuración.
class BusinessSetupScope extends InheritedWidget {
  const BusinessSetupScope({
    super.key,
    required this.gate,
    required super.child,
  });

  final BusinessSetupGate gate;

  /// No hace nada si no hay [BusinessSetupScope] arriba (p. ej. en tests).
  static void refresh(BuildContext context) => context
      .getInheritedWidgetOfExactType<BusinessSetupScope>()
      ?.gate
      .refresh();

  @override
  bool updateShouldNotify(BusinessSetupScope oldWidget) =>
      gate != oldWidget.gate;
}
