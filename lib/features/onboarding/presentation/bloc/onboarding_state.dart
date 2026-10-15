part of 'onboarding_bloc.dart';

final class OnboardingState extends Equatable {
  const OnboardingState({this.page = 0, this.completed = false});

  static const pageCount = 3;

  final int page;
  final bool completed;

  bool get isLastPage => page == pageCount - 1;

  OnboardingState copyWith({int? page, bool? completed}) => OnboardingState(
    page: page ?? this.page,
    completed: completed ?? this.completed,
  );

  @override
  List<Object?> get props => [page, completed];
}
