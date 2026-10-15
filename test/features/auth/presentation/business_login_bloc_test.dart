import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/auth/domain/entities/auth_failure.dart';
import 'package:mi_cancha/features/auth/domain/entities/auth_user.dart';
import 'package:mi_cancha/features/auth/domain/entities/email_credentials.dart';
import 'package:mi_cancha/features/auth/domain/entities/user_role.dart';
import 'package:mi_cancha/features/auth/domain/usecases/sign_in_with_credentials.dart';
import 'package:mi_cancha/features/auth/presentation/bloc/business_login/business_login_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignIn extends Mock implements SignInWithCredentials {}

void main() {
  const user = AuthUser(
    id: '1',
    displayName: 'Negocio',
    role: UserRole.adminNegocio,
  );
  late _MockSignIn signIn;

  setUpAll(
    () =>
        registerFallbackValue(const EmailCredentials(email: '', password: '')),
  );
  setUp(() => signIn = _MockSignIn());

  blocTest<BusinessLoginBloc, BusinessLoginState>(
    'loading → success y envía el correo sin espacios',
    setUp: () => when(() => signIn(any())).thenAnswer((_) async => user),
    build: () => BusinessLoginBloc(signInWithCredentials: signIn),
    act: (bloc) => bloc.add(
      const BusinessLoginSubmitted(email: ' a@b.co ', password: '123'),
    ),
    expect: () => const [
      BusinessLoginState(status: BusinessLoginStatus.loading),
      BusinessLoginState(status: BusinessLoginStatus.success),
    ],
    verify: (_) => verify(
      () => signIn(const EmailCredentials(email: 'a@b.co', password: '123')),
    ).called(1),
  );

  for (final failure in AuthFailure.values) {
    blocTest<BusinessLoginBloc, BusinessLoginState>(
      'loading → failure con el motivo $failure',
      setUp: () => when(() => signIn(any())).thenThrow(AuthException(failure)),
      build: () => BusinessLoginBloc(signInWithCredentials: signIn),
      act: (bloc) => bloc.add(
        const BusinessLoginSubmitted(email: 'a@b.co', password: '123'),
      ),
      expect: () => [
        const BusinessLoginState(status: BusinessLoginStatus.loading),
        BusinessLoginState(
          status: BusinessLoginStatus.failure,
          failure: failure,
        ),
      ],
    );
  }

  blocTest<BusinessLoginBloc, BusinessLoginState>(
    'un error inesperado se trata como error del servidor',
    setUp: () => when(() => signIn(any())).thenThrow(Exception('x')),
    build: () => BusinessLoginBloc(signInWithCredentials: signIn),
    act: (bloc) => bloc.add(
      const BusinessLoginSubmitted(email: 'a@b.co', password: '123'),
    ),
    expect: () => const [
      BusinessLoginState(status: BusinessLoginStatus.loading),
      BusinessLoginState(
        status: BusinessLoginStatus.failure,
        failure: AuthFailure.server,
      ),
    ],
  );
}
