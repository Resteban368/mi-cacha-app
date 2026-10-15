abstract interface class OnboardingRepository {
  /// `true` si el usuario ya completó u omitió el onboarding.
  Future<bool> isCompleted();

  Future<void> markCompleted();
}
