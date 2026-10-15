/// Motivos por los que puede fallar un inicio de sesión.
enum AuthFailure {
  /// Correo o contraseña incorrectos.
  invalidCredentials,

  /// La cuenta existe pero no es de administrador de negocio.
  notBusinessAccount,

  /// Sin conexión o la API no respondió a tiempo.
  network,

  /// Error inesperado del servidor.
  server,
}

class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'AuthException($failure)';
}
