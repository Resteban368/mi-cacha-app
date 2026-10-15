/// Roles de la plataforma.
enum UserRole {
  superAdmin('SUPER_ADMIN'),
  adminNegocio('ADMIN_NEGOCIO'),
  jugador('JUGADOR');

  const UserRole(this.apiValue);

  /// Valor que envía la API.
  final String apiValue;

  /// `null` si la API envía un rol desconocido.
  static UserRole? fromApi(String? value) {
    for (final role in values) {
      if (role.apiValue == value) return role;
    }
    return null;
  }
}
