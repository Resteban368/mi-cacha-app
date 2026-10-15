import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:mi_cancha/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockComplete extends Mock implements CompleteOnboarding {}

void main() {
  late _MockComplete complete;

  setUpAll(() => registerFallbackValue(const NoParams()));
  setUp(() {
    complete = _MockComplete();
    when(() => complete(any())).thenAnswer((_) async {});
  });

  OnboardingBloc build() => OnboardingBloc(completeOnboarding: complete);

  blocTest<OnboardingBloc, OnboardingState>(
    'actualiza la página y la limita al rango válido',
    build: build,
    act: (bloc) => bloc
      ..add(const OnboardingPageChanged(2))
      ..add(const OnboardingPageChanged(7)),
    expect: () => const [OnboardingState(page: 2)],
  );

  test('isLastPage solo en el paso 3', () {
    expect(const OnboardingState(page: 1).isLastPage, isFalse);
    expect(const OnboardingState(page: 2).isLastPage, isTrue);
  });

  blocTest<OnboardingBloc, OnboardingState>(
    'al finalizar guarda la bandera una sola vez',
    build: build,
    act: (bloc) => bloc
      ..add(const OnboardingFinished())
      ..add(const OnboardingFinished()),
    expect: () => const [OnboardingState(completed: true)],
    verify: (_) => verify(() => complete(any())).called(1),
  );
}
