import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/auth/domain/entities/user_role.dart';
import 'package:mi_cancha/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:mi_cancha/features/splash/domain/entities/start_destination.dart';
import 'package:mi_cancha/features/splash/domain/repositories/session_repository.dart';
import 'package:mi_cancha/features/splash/domain/usecases/resolve_start_destination.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionRepository extends Mock implements SessionRepository {}

class _MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  late _MockSessionRepository session;
  late _MockOnboardingRepository onboarding;
  late ResolveStartDestination useCase;

  setUp(() {
    session = _MockSessionRepository();
    onboarding = _MockOnboardingRepository();
    useCase = ResolveStartDestination(session, onboarding);
  });

  group('con sesión guardada', () {
    test('un administrador de negocio va a su panel', () async {
      when(
        () => session.activeRole(),
      ).thenAnswer((_) async => UserRole.adminNegocio);
      expect(await useCase(const NoParams()), StartDestination.businessHome);
      verifyNever(() => onboarding.isCompleted());
    });

    test('un jugador va al home', () async {
      when(
        () => session.activeRole(),
      ).thenAnswer((_) async => UserRole.jugador);
      expect(await useCase(const NoParams()), StartDestination.home);
    });
  });

  group('sin sesión', () {
    setUp(() => when(() => session.activeRole()).thenAnswer((_) async => null));

    test('devuelve onboarding la primera vez', () async {
      when(() => onboarding.isCompleted()).thenAnswer((_) async => false);
      expect(await useCase(const NoParams()), StartDestination.onboarding);
    });

    test('devuelve login con el onboarding completado', () async {
      when(() => onboarding.isCompleted()).thenAnswer((_) async => true);
      expect(await useCase(const NoParams()), StartDestination.login);
    });
  });
}
