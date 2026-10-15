import '../entities/auth_method.dart';
import '../entities/auth_user.dart';
import '../entities/email_credentials.dart';

abstract interface class AuthRepository {
  /// Acceso de jugadores (Google, Apple o correo).
  Future<AuthUser> signIn(AuthMethod method);

  /// Acceso de administradores de negocio con correo y contraseña. Guarda la
  /// sesión si todo va bien; lanza `AuthException` si no.
  Future<AuthUser> signInWithCredentials(EmailCredentials credentials);

  /// Cierra la sesión y borra el token guardado.
  Future<void> signOut();
}
