import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/complete_onboarding.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({required CompleteOnboarding completeOnboarding})
    : _completeOnboarding = completeOnboarding,
      super(const OnboardingState()) {
    on<OnboardingPageChanged>(_onPageChanged);
    on<OnboardingFinished>(_onFinished, transformer: droppable());
  }

  final CompleteOnboarding _completeOnboarding;

  void _onPageChanged(
    OnboardingPageChanged event,
    Emitter<OnboardingState> emit,
  ) {
    final page = event.page.clamp(0, OnboardingState.pageCount - 1);
    emit(state.copyWith(page: page));
  }

  Future<void> _onFinished(
    OnboardingFinished event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state.completed) return;
    await _completeOnboarding(const NoParams());
    emit(state.copyWith(completed: true));
  }
}
