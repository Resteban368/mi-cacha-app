import 'package:equatable/equatable.dart';

/// Sesión iniciada contra la API.
final class Session extends Equatable {
  const Session({
    required this.accessToken,
    required this.role,
    required this.displayName,
  });

  /// Rol del backend del administrador de negocio.
  static const businessAdminRole = 'ADMIN_NEGOCIO';

  final String accessToken;

  /// Rol tal como lo envía la API (`ADMIN_NEGOCIO`, `JUGADOR`, …).
  final String role;
  final String displayName;

  bool get isBusinessAdmin => role == businessAdminRole;

  // Nunca exponer el token en logs.
  @override
  String toString() => 'Session($role, $displayName, ***)';

  @override
  List<Object?> get props => [accessToken, role, displayName];
}
