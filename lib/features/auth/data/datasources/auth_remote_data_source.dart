import '../../domain/entities/auth_method.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/user_role.dart';

/// Acceso de jugadores (Google, Apple o correo).
abstract interface class AuthRemoteDataSource {
  Future<AuthUser> signIn(AuthMethod method);
}

/// Simula el inicio de sesión de jugadores: la API aún no tiene ese acceso.
/// TODO: reemplazar por la implementación real cuando exista el endpoint.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  const FakeAuthRemoteDataSource({this.latency = const Duration(seconds: 2)});

  final Duration latency;

  @override
  Future<AuthUser> signIn(AuthMethod method) async {
    await Future<void>.delayed(latency);
    return const AuthUser(
      id: 'demo-jugador',
      displayName: 'Jugador Demo',
      role: UserRole.jugador,
    );
  }
}
