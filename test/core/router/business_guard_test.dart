import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/router/app_router.dart';
import 'package:mi_cancha/core/router/app_routes.dart';
import 'package:mi_cancha/core/session/session.dart';
import 'package:mi_cancha/core/session/session_manager.dart';
import 'package:mi_cancha/core/session/session_storage.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements SessionStorage {}

void main() {
  SessionManager managerWith(Session? stored) {
    final storage = _MockStorage();
    when(() => storage.read()).thenAnswer((_) async => stored);
    return SessionManager(storage);
  }

  const admin = Session(
    accessToken: 'tok',
    role: 'ADMIN_NEGOCIO',
    displayName: 'Andrés',
  );
  const player = Session(accessToken: 'tok', role: 'JUGADOR', displayName: 'J');

  test('las rutas fuera del panel no se tocan', () async {
    final session = managerWith(null);
    for (final path in [
      AppRoutes.splash,
      AppRoutes.login,
      AppRoutes.onboarding,
      AppRoutes.home,
    ]) {
      expect(await businessGuard(session, path), isNull);
    }
  });

  test('sin sesión el panel redirige al login de negocio', () async {
    final session = managerWith(null);
    expect(
      await businessGuard(session, AppRoutes.businessReservations),
      AppRoutes.businessLogin,
    );
    expect(await businessGuard(session, AppRoutes.businessLogin), isNull);
  });

  test('un jugador tampoco entra al panel', () async {
    expect(
      await businessGuard(managerWith(player), AppRoutes.businessPayments),
      AppRoutes.businessLogin,
    );
  });

  test('con sesión de admin entra y el login lleva al panel', () async {
    final session = managerWith(admin);
    expect(await businessGuard(session, AppRoutes.businessPayments), isNull);
    expect(
      await businessGuard(session, AppRoutes.businessLogin),
      AppRoutes.businessReservations,
    );
  });
}
