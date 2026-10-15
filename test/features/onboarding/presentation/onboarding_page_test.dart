import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/router/app_routes.dart';
import 'package:mi_cancha/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:mi_cancha/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockBloc extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const OnboardingFinished());
  });

  late _MockBloc bloc;
  setUp(() => bloc = _MockBloc());

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: AppRoutes.onboarding,
          routes: [
            GoRoute(
              path: AppRoutes.onboarding,
              builder: (_, _) => BlocProvider<OnboardingBloc>.value(
                value: bloc,
                child: const OnboardingPage(),
              ),
            ),
            GoRoute(
              path: AppRoutes.login,
              builder: (_, _) => const Text('login-page'),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
  }

  // Los puntos "en vivo" animan en bucle: avanzar un tiempo fijo.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('Siguiente avanza al paso 2 y Volver regresa', (tester) async {
    when(() => bloc.state).thenReturn(const OnboardingState());
    await pumpPage(tester);
    expect(find.text('Todas las canchas de tu ciudad'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await settle(tester);
    expect(find.text('Mira la disponibilidad al instante'), findsOneWidget);
    verify(() => bloc.add(const OnboardingPageChanged(1))).called(1);

    // El bloc refleja la página actual para que "Volver" sepa a dónde ir.
    when(() => bloc.state).thenReturn(const OnboardingState(page: 1));
    await tester.tap(find.byTooltip('Volver'));
    await settle(tester);
    expect(find.text('Todas las canchas de tu ciudad'), findsOneWidget);
  });

  testWidgets('se puede deslizar entre pasos', (tester) async {
    when(() => bloc.state).thenReturn(const OnboardingState());
    await pumpPage(tester);

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await settle(tester);
    expect(find.text('Mira la disponibilidad al instante'), findsOneWidget);
  });

  testWidgets('Saltar finaliza el onboarding', (tester) async {
    when(() => bloc.state).thenReturn(const OnboardingState());
    await pumpPage(tester);

    await tester.tap(find.text('Saltar'));
    verify(() => bloc.add(const OnboardingFinished())).called(1);
  });

  testWidgets('navega al login al completarse', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable(const [OnboardingState(completed: true)]),
      initialState: const OnboardingState(),
    );
    await pumpPage(tester);
    await tester.pump();

    expect(find.text('login-page'), findsOneWidget);
  });
}
