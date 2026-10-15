import '../../../../core/usecase/usecase.dart';
import '../repositories/onboarding_repository.dart';

class CompleteOnboarding implements UseCase<void, NoParams> {
  const CompleteOnboarding(this._repository);

  final OnboardingRepository _repository;

  @override
  Future<void> call(NoParams params) => _repository.markCompleted();
}
