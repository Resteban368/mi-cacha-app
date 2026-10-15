import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/auth/domain/entities/auth_method.dart';
import 'package:mi_cancha/features/auth/domain/entities/auth_user.dart';
import 'package:mi_cancha/features/auth/domain/entities/user_role.dart';
import 'package:mi_cancha/features/auth/domain/usecases/sign_in.dart';
import 'package:mi_cancha/features/auth/presentation/bloc/login_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignIn extends Mock implements SignIn {}

void main() {
  const user = AuthUser(id: '1', displayName: 'Demo', role: UserRole.jugador);
  late _MockSignIn signIn;

  setUpAll(() => registerFallbackValue(AuthMethod.google));
  setUp(() => signIn = _MockSignIn());

  blocTest<LoginBloc, LoginState>(
    'loading → success al iniciar sesión',
    setUp: () => when(() => signIn(any())).thenAnswer((_) async => user),
    build: () => LoginBloc(signIn: signIn),
    act: (bloc) => bloc.add(const LoginRequested(AuthMethod.google)),
    expect: () => const [
      LoginState(status: LoginStatus.loading, method: AuthMethod.google),
      LoginState(status: LoginStatus.success, method: AuthMethod.google),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'loading → failure si el inicio falla',
    setUp: () => when(() => signIn(any())).thenThrow(Exception('x')),
    build: () => LoginBloc(signIn: signIn),
    act: (bloc) => bloc.add(const LoginRequested(AuthMethod.apple)),
    expect: () => const [
      LoginState(status: LoginStatus.loading, method: AuthMethod.apple),
      LoginState(status: LoginStatus.failure, method: AuthMethod.apple),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'ignora solicitudes mientras hay una en curso',
    build: () => LoginBloc(signIn: signIn),
    act: (bloc) async {
      final pending = Completer<AuthUser>();
      when(() => signIn(any())).thenAnswer((_) => pending.future);
      bloc.add(const LoginRequested(AuthMethod.google));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const LoginRequested(AuthMethod.email));
      await Future<void>.delayed(Duration.zero);
      pending.complete(user);
    },
    expect: () => const [
      LoginState(status: LoginStatus.loading, method: AuthMethod.google),
      LoginState(status: LoginStatus.success, method: AuthMethod.google),
    ],
    verify: (_) => verify(() => signIn(AuthMethod.google)).called(1),
  );
}
