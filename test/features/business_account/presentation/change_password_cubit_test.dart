import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_account/domain/entities/password_change.dart';
import 'package:mi_cancha/features/business_account/domain/usecases/change_password.dart';
import 'package:mi_cancha/features/business_account/presentation/bloc/change_password_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockChangePassword extends Mock implements ChangePassword {}

void main() {
  const change = PasswordChange(
    currentPassword: 'actual123',
    newPassword: 'nueva12345',
  );
  const submitting = ChangePasswordState(
    status: ChangePasswordStatus.submitting,
  );

  late _MockChangePassword changePassword;

  setUpAll(() => registerFallbackValue(change));
  setUp(() => changePassword = _MockChangePassword());

  ChangePasswordCubit build() =>
      ChangePasswordCubit(changePassword: changePassword);

  blocTest<ChangePasswordCubit, ChangePasswordState>(
    'éxito: envía el cambio y termina en success',
    setUp: () => when(() => changePassword(any())).thenAnswer((_) async {}),
    build: build,
    act: (cubit) => cubit.submit(change),
    expect: () => const [
      submitting,
      ChangePasswordState(status: ChangePasswordStatus.success),
    ],
    verify: (_) => verify(() => changePassword(change)).called(1),
  );

  blocTest<ChangePasswordCubit, ChangePasswordState>(
    'contraseña actual incorrecta: guarda el mensaje de la API',
    setUp: () => when(() => changePassword(any())).thenThrow(
      const PasswordChangeException(
        PasswordChangeFailure.rejected,
        message: 'La contraseña actual no es correcta',
      ),
    ),
    build: build,
    act: (cubit) => cubit.submit(change),
    expect: () => const [
      submitting,
      ChangePasswordState(
        status: ChangePasswordStatus.failure,
        failure: PasswordChangeFailure.rejected,
        message: 'La contraseña actual no es correcta',
      ),
    ],
  );

  blocTest<ChangePasswordCubit, ChangePasswordState>(
    'sin conexión',
    setUp: () => when(
      () => changePassword(any()),
    ).thenThrow(const PasswordChangeException(PasswordChangeFailure.network)),
    build: build,
    act: (cubit) => cubit.submit(change),
    expect: () => const [
      submitting,
      ChangePasswordState(
        status: ChangePasswordStatus.failure,
        failure: PasswordChangeFailure.network,
      ),
    ],
  );

  blocTest<ChangePasswordCubit, ChangePasswordState>(
    'un error inesperado queda como error del servidor',
    setUp: () => when(() => changePassword(any())).thenThrow(Exception()),
    build: build,
    act: (cubit) => cubit.submit(change),
    expect: () => const [
      submitting,
      ChangePasswordState(
        status: ChangePasswordStatus.failure,
        failure: PasswordChangeFailure.server,
      ),
    ],
  );

  blocTest<ChangePasswordCubit, ChangePasswordState>(
    'reintentar tras un error limpia el mensaje anterior',
    setUp: () => when(() => changePassword(any())).thenAnswer((_) async {}),
    build: build,
    seed: () => const ChangePasswordState(
      status: ChangePasswordStatus.failure,
      failure: PasswordChangeFailure.rejected,
      message: 'La contraseña actual no es correcta',
    ),
    act: (cubit) => cubit.submit(change),
    expect: () => const [
      submitting,
      ChangePasswordState(status: ChangePasswordStatus.success),
    ],
  );

  blocTest<ChangePasswordCubit, ChangePasswordState>(
    'un segundo envío mientras responde la API se ignora',
    setUp: () => when(
      () => changePassword(any()),
    ).thenAnswer((_) => Future<void>.delayed(const Duration(milliseconds: 10))),
    build: build,
    act: (cubit) => cubit
      ..submit(change)
      ..submit(change),
    wait: const Duration(milliseconds: 20),
    expect: () => const [
      submitting,
      ChangePasswordState(status: ChangePasswordStatus.success),
    ],
    verify: (_) => verify(() => changePassword(any())).called(1),
  );
}
