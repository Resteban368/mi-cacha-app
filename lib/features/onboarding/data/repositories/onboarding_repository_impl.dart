import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_data_source.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._localDataSource);

  final OnboardingLocalDataSource _localDataSource;

  @override
  Future<bool> isCompleted() async {
    try {
      return await _localDataSource.readCompleted();
    } catch (_) {
      // Si el almacenamiento falla, mostrar el onboarding de nuevo es inocuo.
      return false;
    }
  }

  @override
  Future<void> markCompleted() async {
    try {
      await _localDataSource.writeCompleted();
    } catch (_) {
      // No bloquear al usuario: en el peor caso verá el onboarding otra vez.
    }
  }
}
