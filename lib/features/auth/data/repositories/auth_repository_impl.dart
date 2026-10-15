import '../../../../core/network/api_exception.dart';
import '../../../../core/session/session.dart';
import '../../../../core/session/session_manager.dart';
import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/auth_method.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/email_credentials.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/business_auth_api_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource playerDataSource,
    required BusinessAuthApiDataSource businessApi,
    required SessionManager session,
  }) : _playerDataSource = playerDataSource,
       _businessApi = businessApi,
       _session = session;

  final AuthRemoteDataSource _playerDataSource;
  final BusinessAuthApiDataSource _businessApi;
  final SessionManager _session;

  @override
  Future<AuthUser> signIn(AuthMethod method) =>
      _playerDataSource.signIn(method);

  @override
  Future<AuthUser> signInWithCredentials(EmailCredentials credentials) async {
    final BusinessLoginResponse response;
    try {
      response = await _businessApi.login(credentials);
    } on ApiException catch (error) {
      throw AuthException(switch (error.kind) {
        // 400: el backend rechazó el formato (p. ej. correo inválido).
        ApiErrorKind.unauthorized ||
        ApiErrorKind.badRequest => AuthFailure.invalidCredentials,
        ApiErrorKind.forbidden => AuthFailure.notBusinessAccount,
        ApiErrorKind.network => AuthFailure.network,
        _ => AuthFailure.server,
      });
    }

    final role = UserRole.fromApi(response.role);
    // Solo administradores de negocio entran al panel; no se guarda nada.
    if (role != UserRole.adminNegocio) {
      throw const AuthException(AuthFailure.notBusinessAccount);
    }

    await _session.start(
      Session(
        accessToken: response.accessToken,
        role: response.role,
        displayName: response.displayName,
      ),
    );
    return AuthUser(
      id: response.id,
      displayName: response.displayName,
      role: role!,
    );
  }

  @override
  Future<void> signOut() => _session.end();
}
