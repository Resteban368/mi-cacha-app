part of 'onboarding_bloc.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

/// La página visible cambió (deslizando o con los botones).
final class OnboardingPageChanged extends OnboardingEvent {
  const OnboardingPageChanged(this.page);

  final int page;

  @override
  List<Object?> get props => [page];
}

/// "Saltar", "Empezar ahora" o "Inicia Sesión".
final class OnboardingFinished extends OnboardingEvent {
  const OnboardingFinished();
}
