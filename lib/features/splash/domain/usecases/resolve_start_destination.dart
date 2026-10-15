import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../onboarding/domain/repositories/onboarding_repository.dart';
import '../entities/start_destination.dart';
import '../repositories/session_repository.dart';

class ResolveStartDestination implements UseCase<StartDestination, NoParams> {
  const ResolveStartDestination(
    this._sessionRepository,
    this._onboardingRepository,
  );

  final SessionRepository _sessionRepository;
  final OnboardingRepository _onboardingRepository;

  /// Con sesión guardada se entra directo según el rol (aunque sea la
  /// primera apertura en este dispositivo); sin sesión, onboarding la primera
  /// vez y luego el login.
  @override
  Future<StartDestination> call(NoParams params) async {
    final role = await _sessionRepository.activeRole();
    if (role == UserRole.adminNegocio) return StartDestination.businessHome;
    if (role != null) return StartDestination.home;
    if (!await _onboardingRepository.isCompleted()) {
      return StartDestination.onboarding;
    }
    return StartDestination.login;
  }
}
