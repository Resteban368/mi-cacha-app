import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/router/app_routes.dart';
import 'package:mi_cancha/features/auth/domain/entities/auth_failure.dart';
import 'package:mi_cancha/features/auth/presentation/bloc/business_login/business_login_bloc.dart';
import 'package:mi_cancha/features/auth/presentation/pages/business_login_page.dart';
import 'package:mi_cancha/features/auth/presentation/widgets/business_login_header.dart';
import 'package:mocktail/mocktail.dart';

class _MockBloc extends MockBloc<BusinessLoginEvent, BusinessLoginState>
    implements BusinessLoginBloc {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(
      const BusinessLoginSubmitted(email: '', password: ''),
    );
  });

  late _MockBloc bloc;
  setUp(() => bloc = _MockBloc());

  Future<void> pumpPage(
    WidgetTester tester, {
    String initialLocation = AppRoutes.businessLogin,
    Size size = const Size(390, 900),
    bool sessionExpired = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: initialLocation,
          routes: [
            GoRoute(
              path: AppRoutes.login,
              builder: (_, _) => const Text('login-page'),
            ),
            GoRoute(
              path: AppRoutes.businessLogin,
              builder: (_, _) => BlocProvider<BusinessLoginBloc>.value(
                value: bloc,
                child: BusinessLoginPage(sessionExpired: sessionExpired),
              ),
            ),
            GoRoute(
              path: AppRoutes.businessReservations,
              builder: (_, _) => const Text('home-page'),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('valida campos vacíos sin enviar', (tester) async {
    when(() => bloc.state).thenReturn(const BusinessLoginState());
    await pumpPage(tester);

    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('envía las credenciales cuando el formulario es válido', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(const BusinessLoginState());
    await pumpPage(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.co');
    await tester.enterText(find.byType(TextFormField).at(1), 'secreto');
    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    verify(
      () => bloc.add(
        const BusinessLoginSubmitted(email: 'a@b.co', password: 'secreto'),
      ),
    ).called(1);
  });

  testWidgets('alterna la visibilidad de la contraseña', (tester) async {
    when(() => bloc.state).thenReturn(const BusinessLoginState());
    await pumpPage(tester);

    EditableText password() =>
        tester.widget<EditableText>(find.byType(EditableText).at(1));
    expect(password().obscureText, isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(password().obscureText, isFalse);
  });

  testWidgets('navega tras un inicio exitoso', (tester) async {
    whenListen(
      bloc,
      Stream.fromIterable(const [
        BusinessLoginState(status: BusinessLoginStatus.success),
      ]),
      initialState: const BusinessLoginState(
        status: BusinessLoginStatus.loading,
      ),
    );
    await pumpPage(tester);
    await tester.pump();

    expect(find.text('home-page'), findsOneWidget);
  });

  testWidgets('sin acceso de jugadores no muestra "Volver"', (tester) async {
    when(() => bloc.state).thenReturn(const BusinessLoginState());
    await pumpPage(tester);
    expect(find.byTooltip('Volver al acceso de jugadores'), findsNothing);

    await pumpPage(tester, size: const Size(1440, 900));
    expect(find.byTooltip('Volver al acceso de jugadores'), findsNothing);
  });

  group('layout web', () {
    testWidgets('en pantalla ancha muestra panel y formulario lado a lado', (
      tester,
    ) async {
      when(() => bloc.state).thenReturn(const BusinessLoginState());
      await pumpPage(tester, size: const Size(1440, 900));

      final panel = tester.getRect(find.byType(BusinessLoginHeader));
      final welcome = tester.getRect(find.text('Bienvenido de nuevo'));
      expect(panel.height, greaterThan(800));
      expect(welcome.left, greaterThan(panel.right));
      expect(find.textContaining('desde un solo lugar'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'a@b.co');
      await tester.enterText(find.byType(TextFormField).at(1), 'secreto');
      await tester.tap(find.text('Ingresar'));
      await tester.pump();
      verify(
        () => bloc.add(
          const BusinessLoginSubmitted(email: 'a@b.co', password: 'secreto'),
        ),
      ).called(1);
    });

    testWidgets('en móvil mantiene la hoja inferior', (tester) async {
      when(() => bloc.state).thenReturn(const BusinessLoginState());
      await pumpPage(tester);

      expect(find.textContaining('desde un solo lugar'), findsNothing);
      final header = tester.getRect(find.byType(BusinessLoginHeader));
      final welcome = tester.getRect(find.text('Bienvenido de nuevo'));
      expect(welcome.top, greaterThan(header.bottom));
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
        when(() => bloc.state).thenReturn(const BusinessLoginState());
        await pumpPage(tester, size: size);

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('mensajes de error', () {
    for (final (failure, message) in const [
      (AuthFailure.invalidCredentials, 'Correo o contraseña incorrectos.'),
      (
        AuthFailure.notBusinessAccount,
        'Esta cuenta no es de administrador de negocio.',
      ),
      (
        AuthFailure.network,
        'Sin conexión con el servidor. Revisa tu internet e intenta de nuevo.',
      ),
      (
        AuthFailure.server,
        'No pudimos iniciar sesión. Intenta de nuevo en unos minutos.',
      ),
    ]) {
      testWidgets('$failure', (tester) async {
        whenListen(
          bloc,
          Stream.fromIterable([
            BusinessLoginState(
              status: BusinessLoginStatus.failure,
              failure: failure,
            ),
          ]),
          initialState: const BusinessLoginState(
            status: BusinessLoginStatus.loading,
          ),
        );
        await pumpPage(tester);
        await tester.pump();

        expect(find.text(message), findsOneWidget);
      });
    }
  });

  testWidgets('avisa cuando la sesión venció', (tester) async {
    when(() => bloc.state).thenReturn(const BusinessLoginState());
    await pumpPage(tester, sessionExpired: true);
    await tester.pump();

    expect(
      find.text('Tu sesión venció. Ingresa de nuevo para continuar.'),
      findsOneWidget,
    );
  });
}
