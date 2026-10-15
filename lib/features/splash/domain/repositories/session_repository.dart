import '../../../auth/domain/entities/user_role.dart';

abstract interface class SessionRepository {
  /// Rol de la sesión guardada localmente (soporta modo offline);
  /// `null` si no hay sesión o el rol no se reconoce.
  Future<UserRole?> activeRole();
}
