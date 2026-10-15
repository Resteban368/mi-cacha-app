import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/router/app_routes.dart';
import 'package:mi_cancha/features/auth/domain/entities/auth_method.dart';
import 'package:mi_cancha/features/auth/presentation/bloc/login_bloc.dart';
import 'package:mi_cancha/features/auth/presentation/pages/login_page.dart';
import 'package:mi_cancha/features/auth/presentation/widgets/login_hero.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const LoginRequested(AuthMethod.google));
  });

  late _MockLoginBloc bloc;
  setUp(() => bloc = _MockLoginBloc());

  Widget app() => MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: AppRoutes.login,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => BlocProvider<LoginBloc>.value(
            value: bloc,
            child: const LoginPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const Text('home-page'),
        ),
        GoRoute(
          path: AppRoutes.businessLogin,
          builder: (_, _) => const Text('business-login-page'),
        ),
      ],
    ),
  );

  testWidgets('muestra los accesos y envía el método elegido', (tester) async {
    when(() => bloc.state).thenReturn(const LoginState());
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('Continuar con Apple'), findsOneWidget);
    expect(find.text('Continuar con correo electrónico'), findsOneWidget);

    await tester.tap(find.text('Continuar con Apple'));
    verify(() => bloc.add(const LoginRequested(AuthMethod.apple))).called(1);
  });

  testWidgets('muestra loader y bloquea los demás botones al cargar', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(
      const LoginState(status: LoginStatus.loading, method: AuthMethod.google),
    );
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Continuar con Apple'));
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('navega tras un inicio de sesión exitoso', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable(const [
        LoginState(status: LoginStatus.success, method: AuthMethod.email),
      ]),
      initialState: const LoginState(
        status: LoginStatus.loading,
        method: AuthMethod.email,
      ),
    );
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump();

    expect(find.text('home-page'), findsOneWidget);
  });

  testWidgets('Modo Centro abre el login de negocio', (tester) async {
    when(() => bloc.state).thenReturn(const LoginState());
    await tester.pumpWidget(app());
    await tester.pump();

    await tester.ensureVisible(find.text('Modo Centro'));
    await tester.tap(find.text('Modo Centro'));
    await tester.pumpAndSettle();

    expect(find.text('business-login-page'), findsOneWidget);
  });

  group('layout web', () {
    void setSize(WidgetTester tester, Size size) {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('en pantalla ancha muestra hero y accesos lado a lado', (
      tester,
    ) async {
      setSize(tester, const Size(1440, 900));
      when(() => bloc.state).thenReturn(const LoginState());
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Te damos la bienvenida'), findsOneWidget);
      final hero = tester.getRect(find.byType(LoginHero));
      final google = tester.getRect(find.text('Continuar con Google'));
      expect(hero.height, greaterThan(800));
      expect(google.left, greaterThan(hero.right));

      await tester.tap(find.text('Continuar con Google'));
      verify(() => bloc.add(const LoginRequested(AuthMethod.google))).called(1);
    });

    testWidgets('en móvil mantiene el hero arriba sin bienvenida', (
      tester,
    ) async {
      setSize(tester, const Size(412, 915));
      when(() => bloc.state).thenReturn(const LoginState());
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.text('Te damos la bienvenida'), findsNothing);
      final hero = tester.getRect(find.byType(LoginHero));
      final google = tester.getRect(find.text('Continuar con Google'));
      expect(google.top, greaterThan(hero.top + hero.height / 2));
    });

    for (final size in const [
      Size(320, 568),
      Size(900, 560),
      Size(1024, 600),
      Size(1920, 1080),
      Size(1200, 500),
    ]) {
      testWidgets('sin desbordes en ${size.width}x${size.height}', (
        tester,
      ) async {
        setSize(tester, size);
        when(() => bloc.state).thenReturn(const LoginState());
        await tester.pumpWidget(app());
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }
  });
}
