import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/router/app_routes.dart';
import 'package:mi_cancha/features/business_account/domain/entities/business_account.dart';
import 'package:mi_cancha/features/business_account/domain/usecases/change_password.dart';
import 'package:mi_cancha/features/business_account/presentation/bloc/business_account_bloc.dart';
import 'package:mi_cancha/features/business_account/presentation/bloc/change_password_cubit.dart';
import 'package:mi_cancha/features/business_account/presentation/pages/business_account_page.dart';
import 'package:mi_cancha/features/business_account/presentation/widgets/account_profile_card.dart';
import 'package:mi_cancha/features/business_account/presentation/widgets/account_settings_card.dart';
import 'package:mi_cancha/features/business_account/presentation/widgets/subscription_card.dart';
import 'package:mocktail/mocktail.dart';

import '../../business_profile/business_fixtures.dart';
import '../account_fixtures.dart';

class _MockBloc extends MockBloc<BusinessAccountEvent, BusinessAccountState>
    implements BusinessAccountBloc {}

class _MockChangePassword extends Mock implements ChangePassword {}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late _MockBloc bloc;
  setUp(() => bloc = _MockBloc());

  final ready = BusinessAccountState(
    status: BusinessAccountStatus.ready,
    account: account,
    venue: business,
    version: '1.0.0',
  );

  Future<void> pumpPage(
    WidgetTester tester, {
    BusinessAccountState? state,
    Size size = const Size(412, 915),
    ChangePasswordCubit Function()? createChangePasswordCubit,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => bloc.state).thenReturn(state ?? ready);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: AppRoutes.businessSettings,
          routes: [
            GoRoute(
              path: AppRoutes.businessSettings,
              builder: (_, _) => Scaffold(
                body: BlocProvider<BusinessAccountBloc>.value(
                  value: bloc,
                  child: BusinessAccountPage(
                    onSignOut: () async {},
                    createChangePasswordCubit: createChangePasswordCubit,
                  ),
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.businessProfile,
              builder: (_, _) => const Text('profile-page'),
            ),
            GoRoute(
              path: AppRoutes.businessLogin,
              builder: (_, _) => const Text('business-login-page'),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
  }

  // El punto "Activa" pulsa en bucle: se avanza un tiempo fijo en lugar de
  // pumpAndSettle.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  // La lista móvil se arma de forma diferida: desplazar hasta construir el
  // elemento y luego hasta que quede en pantalla.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pump();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await reveal(tester, find.text(text));
    await tester.tap(find.text(text));
    await settle(tester);
  }

  testWidgets('muestra perfil, sede, plan y configuración', (tester) async {
    await pumpPage(tester);

    expect(find.text('Mi cuenta'), findsOneWidget);
    expect(find.text('CR'), findsOneWidget);
    expect(find.text('Carlos Rodríguez'), findsOneWidget);
    expect(find.text('ADMIN PRO'), findsOneWidget);
    expect(find.text(business.name), findsOneWidget);
    expect(find.text('Centro · 3 canchas activas'), findsOneWidget);
    expect(find.text('Plan Básico'), findsOneWidget);
    expect(find.textContaining(r'$79.900'), findsOneWidget);
    expect(find.text('15 sep. 2026'), findsOneWidget);
    expect(find.text('15 oct. 2026'), findsOneWidget);
    expect(find.text('3 de 5 canchas (60%)'), findsOneWidget);
    expect(find.textContaining('Tienes 2 cupos libres'), findsOneWidget);
    await reveal(tester, find.text('Mi Cancha v1.0.0 · Centro'));
    expect(find.text('Mi Cancha v1.0.0 · Centro'), findsOneWidget);
  });

  testWidgets('los beneficios se despliegan al tocarlos', (tester) async {
    await pumpPage(tester);

    expect(find.text('2 activos'), findsOneWidget);
    expect(find.text('Hasta 5 canchas registradas'), findsNothing);

    await tapText(tester, 'Ver beneficios incluidos');
    expect(find.text('Hasta 5 canchas registradas'), findsOneWidget);
    expect(find.text('Reservas ilimitadas'), findsOneWidget);

    await tapText(tester, 'Ver beneficios incluidos');
    expect(find.text('Hasta 5 canchas registradas'), findsNothing);
  });

  testWidgets('la sede lleva a Mi negocio', (tester) async {
    await pumpPage(tester);
    await tapText(tester, business.name);
    expect(find.text('profile-page'), findsOneWidget);
  });

  testWidgets('sin sede invita a registrarla', (tester) async {
    await pumpPage(
      tester,
      state: BusinessAccountState(
        status: BusinessAccountStatus.ready,
        account: account,
      ),
    );

    expect(find.text('Registra tu sede deportiva'), findsOneWidget);
    await tapText(tester, 'Registra tu sede deportiva');
    expect(find.text('profile-page'), findsOneWidget);
  });

  testWidgets('cerrar sesión confirma y va al login de negocio', (
    tester,
  ) async {
    await pumpPage(tester);

    await tapText(tester, 'Cerrar sesión');
    expect(find.text('¿Cerrar sesión?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cerrar sesión'),
      ),
    );
    await settle(tester);

    expect(find.text('business-login-page'), findsOneWidget);
  });

  testWidgets('las acciones pendientes avisan "próximamente"', (tester) async {
    await pumpPage(tester);

    await tapText(tester, 'Cambiar a Plan Pro o Anual');
    expect(find.text('Cambio de plan: próximamente'), findsOneWidget);
    await tapText(tester, 'Cambiar contraseña');
    expect(find.text('Cambiar contraseña: próximamente'), findsOneWidget);
  });

  testWidgets('"Cambiar contraseña" abre el formulario', (tester) async {
    await pumpPage(
      tester,
      createChangePasswordCubit: () =>
          ChangePasswordCubit(changePassword: _MockChangePassword()),
    );

    await tapText(tester, 'Cambiar contraseña');
    expect(find.text('Guardar contraseña'), findsOneWidget);
    expect(find.text('Cambiar contraseña: próximamente'), findsNothing);
  });

  testWidgets('muestra el error y reintenta', (tester) async {
    await pumpPage(
      tester,
      state: const BusinessAccountState(status: BusinessAccountStatus.failure),
    );

    expect(find.text('No pudimos cargar tu cuenta'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    verify(() => bloc.add(const BusinessAccountRequested())).called(1);
  });

  testWidgets('sin plan muestra la tarjeta "Sin plan activo"', (tester) async {
    await pumpPage(
      tester,
      state: BusinessAccountState(
        status: BusinessAccountStatus.ready,
        account: BusinessAccount(admin: account.admin, subscription: null),
        venue: business,
      ),
    );

    expect(find.byType(SubscriptionCard), findsNothing);
    expect(find.text('Sin plan activo'), findsOneWidget);
    expect(find.text('Centro · 0 canchas activas'), findsOneWidget);
    await tapText(tester, 'Ver planes');
    expect(find.text('Planes: próximamente'), findsOneWidget);
  });

  group('layout', () {
    testWidgets('en web el plan va a la derecha de perfil y configuración', (
      tester,
    ) async {
      await pumpPage(tester, size: const Size(1280, 900));

      final profile = tester.getRect(find.byType(AccountProfileCard));
      final settings = tester.getRect(find.byType(AccountSettingsCard));
      final plan = tester.getRect(find.byType(SubscriptionCard));
      expect(plan.left, greaterThan(profile.right));
      expect(settings.top, greaterThan(profile.bottom));
      expect(plan.top, profile.top);
    });

    testWidgets('en móvil todo va en una columna', (tester) async {
      await pumpPage(tester);

      final profile = tester.getRect(find.byType(AccountProfileCard));
      final plan = tester.getRect(find.byType(SubscriptionCard));
      expect(plan.top, greaterThan(profile.bottom));
      expect(plan.left, profile.left);
    });

    for (final size in const [
      Size(320, 568),
      Size(412, 915),
      Size(900, 700),
      Size(1440, 900),
    ]) {
      testWidgets('sin desbordes en ${size.width}x${size.height}', (
        tester,
      ) async {
        await pumpPage(tester, size: size);
        // También con los beneficios abiertos.
        await tapText(tester, 'Ver beneficios incluidos');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
