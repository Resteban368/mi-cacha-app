import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../entities/start_destination.dart';
import '../repositories/session_repository.dart';

class ResolveStartDestination implements UseCase<StartDestination, NoParams> {
  const ResolveStartDestination(this._sessionRepository);

  final SessionRepository _sessionRepository;

  /// Con sesión guardada se entra directo según el rol; sin sesión, al login.
  @override
  Future<StartDestination> call(NoParams params) async {
    final role = await _sessionRepository.activeRole();
    if (role == UserRole.adminNegocio) return StartDestination.businessHome;
    if (role != null) return StartDestination.home;
    return StartDestination.login;
  }
}
