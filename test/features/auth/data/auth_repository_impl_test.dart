import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/network/api_exception.dart';
import 'package:mi_cancha/core/session/session.dart';
import 'package:mi_cancha/core/session/session_manager.dart';
import 'package:mi_cancha/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mi_cancha/features/auth/data/datasources/business_auth_api_data_source.dart';
import 'package:mi_cancha/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mi_cancha/features/auth/domain/entities/auth_failure.dart';
import 'package:mi_cancha/features/auth/domain/entities/auth_user.dart';
import 'package:mi_cancha/features/auth/domain/entities/email_credentials.dart';
import 'package:mi_cancha/features/auth/domain/entities/user_role.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements BusinessAuthApiDataSource {}

class _MockSession extends Mock implements SessionManager {}

class _MockPlayer extends Mock implements AuthRemoteDataSource {}

void main() {
  const credentials = EmailCredentials(email: 'a@b.co', password: '123');
  const session = Session(
    accessToken: 'tok',
    role: 'ADMIN_NEGOCIO',
    displayName: 'Andrés Gómez',
  );

  setUpAll(() {
    registerFallbackValue(credentials);
    registerFallbackValue(session);
  });

  late _MockApi api;
  late _MockSession sessionManager;
  late AuthRepositoryImpl repository;

  setUp(() {
    api = _MockApi();
    sessionManager = _MockSession();
    when(() => sessionManager.start(any())).thenAnswer((_) async {});
    when(() => sessionManager.end()).thenAnswer((_) async {});
    repository = AuthRepositoryImpl(
      playerDataSource: _MockPlayer(),
      businessApi: api,
      session: sessionManager,
    );
  });

  BusinessLoginResponse response(String role) =>
      (accessToken: 'tok', id: 'u1', displayName: 'Andrés Gómez', role: role);

  test('login correcto guarda la sesión y devuelve el usuario', () async {
    when(
      () => api.login(credentials),
    ).thenAnswer((_) async => response('ADMIN_NEGOCIO'));

    final user = await repository.signInWithCredentials(credentials);

    expect(
      user,
      const AuthUser(
        id: 'u1',
        displayName: 'Andrés Gómez',
        role: UserRole.adminNegocio,
      ),
    );
    verify(() => sessionManager.start(session)).called(1);
  });

  test('una cuenta que no es de negocio no se guarda', () async {
    when(
      () => api.login(credentials),
    ).thenAnswer((_) async => response('JUGADOR'));

    await expectLater(
      repository.signInWithCredentials(credentials),
      throwsA(
        isA<AuthException>().having(
          (e) => e.failure,
          'failure',
          AuthFailure.notBusinessAccount,
        ),
      ),
    );
    verifyNever(() => sessionManager.start(any()));
  });

  for (final (kind, failure) in const [
    (ApiErrorKind.unauthorized, AuthFailure.invalidCredentials),
    (ApiErrorKind.badRequest, AuthFailure.invalidCredentials),
    (ApiErrorKind.forbidden, AuthFailure.notBusinessAccount),
    (ApiErrorKind.network, AuthFailure.network),
    (ApiErrorKind.server, AuthFailure.server),
    (ApiErrorKind.unknown, AuthFailure.server),
  ]) {
    test('error $kind → $failure', () async {
      when(() => api.login(any())).thenThrow(ApiException(kind));
      await expectLater(
        repository.signInWithCredentials(credentials),
        throwsA(
          isA<AuthException>().having((e) => e.failure, 'failure', failure),
        ),
      );
      verifyNever(() => sessionManager.start(any()));
    });
  }

  test('signOut cierra la sesión', () async {
    await repository.signOut();
    verify(() => sessionManager.end()).called(1);
  });
}
