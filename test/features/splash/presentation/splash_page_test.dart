import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/router/app_routes.dart';
import 'package:mi_cancha/features/splash/domain/entities/start_destination.dart';
import 'package:mi_cancha/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:mi_cancha/features/splash/presentation/pages/splash_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockSplashBloc extends MockBloc<SplashEvent, SplashState>
    implements SplashBloc {}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late _MockSplashBloc bloc;

  setUp(() => bloc = _MockSplashBloc());

  Widget app() {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (_, _) => BlocProvider<SplashBloc>.value(
            value: bloc,
            child: const SplashPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const Text('login-page'),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Text('home-page'),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('muestra marca y versión', (tester) async {
    when(() => bloc.state).thenReturn(const SplashState(version: '1.0.0'));
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text('Mi Cancha'), findsOneWidget);
    expect(find.text('VERSIÓN 1.0.0'), findsOneWidget);
  });

  testWidgets('navega a login cuando el bloc resuelve el destino', (
    tester,
  ) async {
    whenListen(
      bloc,
      Stream.fromIterable(const [
        SplashState(version: '1.0.0', destination: StartDestination.login),
      ]),
      initialState: const SplashState(version: '1.0.0'),
    );
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump();

    expect(find.text('login-page'), findsOneWidget);
  });
}
