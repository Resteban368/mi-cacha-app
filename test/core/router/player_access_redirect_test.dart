import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/router/app_router.dart';
import 'package:mi_cancha/core/router/app_routes.dart';

void main() {
  test(
    'con el acceso de jugadores oculto, sus rutas van al login de negocio',
    () {
      expect(playerAccessRedirect(AppRoutes.login), AppRoutes.businessLogin);
      expect(playerAccessRedirect(AppRoutes.home), AppRoutes.businessLogin);
      expect(playerAccessRedirect(AppRoutes.onboarding), isNull);
      expect(playerAccessRedirect(AppRoutes.businessReservations), isNull);
    },
  );

  test('habilitado no redirige', () {
    expect(playerAccessRedirect(AppRoutes.login, enabled: true), isNull);
  });
}
