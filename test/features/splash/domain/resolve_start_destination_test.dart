import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/auth/domain/entities/user_role.dart';
import 'package:mi_cancha/features/splash/domain/entities/start_destination.dart';
import 'package:mi_cancha/features/splash/domain/repositories/session_repository.dart';
import 'package:mi_cancha/features/splash/domain/usecases/resolve_start_destination.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late _MockSessionRepository session;
  late ResolveStartDestination useCase;

  setUp(() {
    session = _MockSessionRepository();
    useCase = ResolveStartDestination(session);
  });

  group('con sesión guardada', () {
    test('un administrador de negocio va a su panel', () async {
      when(
        () => session.activeRole(),
      ).thenAnswer((_) async => UserRole.adminNegocio);
      expect(await useCase(const NoParams()), StartDestination.businessHome);
    });

    test('un jugador va al home', () async {
      when(
        () => session.activeRole(),
      ).thenAnswer((_) async => UserRole.jugador);
      expect(await useCase(const NoParams()), StartDestination.home);
    });
  });

  test('sin sesión devuelve login', () async {
    when(() => session.activeRole()).thenAnswer((_) async => null);
    expect(await useCase(const NoParams()), StartDestination.login);
  });
}
