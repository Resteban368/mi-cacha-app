import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/router/app_routes.dart';
import 'package:mi_cancha/core/session/write_access.dart';
import 'package:mi_cancha/core/widgets/app_top_bar.dart';
import 'package:mi_cancha/features/business_home/presentation/navigation/business_section.dart';
import 'package:mi_cancha/features/business_home/presentation/pages/business_home_shell.dart';
import 'package:mi_cancha/features/business_home/presentation/widgets/business_side_menu.dart';
import 'package:mi_cancha/core/session/session.dart';
import 'package:mi_cancha/core/session/session_manager.dart';
import 'package:mi_cancha/core/session/session_storage.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/business_profile/domain/entities/business.dart';
import 'package:mi_cancha/features/business_setup/domain/entities/setup_progress.dart';
import 'package:mi_cancha/features/business_setup/domain/usecases/get_setup_progress.dart';
import 'package:mi_cancha/features/business_setup/presentation/business_setup_gate.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements SessionStorage {}

class _MockGetSetupProgress extends Mock implements GetSetupProgress {}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late GoRouter router;
  var signOuts = 0;
  setUp(() => signOuts = 0);

  Future<void> pumpShell(
    WidgetTester tester, {
    String initialLocation = AppRoutes.businessClients,
    Size size = const Size(390, 844),
    bool canWrite = true,
    BusinessSetupGate? setup,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    GoRoute section(String path, Widget page) =>
        GoRoute(path: path, builder: (_, _) => page);

    router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        ShellRoute(
          builder: (_, state, child) => BusinessHomeShell(
            location: state.uri.path,
            onSignOut: () async => signOuts++,
            setup: setup,
            child: child,
          ),
          routes: [
            // Reservas, Canchas, Mi negocio y Mi cuenta tienen su propio
            // feature;
            // aquí basta un sustituto con el mismo texto.
            section(
              AppRoutes.businessReservations,
              const Center(child: Text('Agenda de tus canchas')),
            ),
            section(
              AppRoutes.businessClients,
              const Column(
                children: [
                  AppTopBar(
                    title: 'Clientes',
                    subtitle:
                        'Directorio de jugadores, fidelidad y contacto directo',
                    icon: Icons.group_rounded,
                  ),
                ],
              ),
            ),
            section(
              AppRoutes.businessDashboard,
              const Column(
                children: [
                  AppTopBar(
                    title: 'Dashboard',
                    subtitle: 'Rendimiento de tu negocio',
                    icon: Icons.insights,
                  ),
                ],
              ),
            ),
            // Con su barra superior: ahí está el botón del menú.
            section(
              AppRoutes.businessCourts,
              const Column(
                children: [
                  AppTopBar(
                    title: 'Canchas',
                    subtitle: 'Tus canchas, horarios y tarifas',
                    icon: Icons.stadium_rounded,
                  ),
                ],
              ),
            ),
            section(
              AppRoutes.businessProfile,
              const Center(child: Text('Datos y ubicación de tu sede')),
            ),
            section(
              AppRoutes.businessSettings,
              const Center(child: Text('Perfil, plan y seguridad')),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.businessLogin,
          builder: (_, _) => const Text('business-login-page'),
        ),
      ],
    );
    await tester.pumpWidget(
      WriteAccessScope(
        notifier: WriteAccess()..update(canWrite: canWrite),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  Finder menuItem(String label) => find.descendant(
    of: find.byType(BusinessSideMenu),
    matching: find.text(label),
  );

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
  }

  group('BusinessSection.fromLocation', () {
    test('mapea cada ruta a su sección', () {
      for (final section in BusinessSection.values) {
        expect(BusinessSection.fromLocation(section.path), section);
      }
    });

    test('todas las secciones usan el ancho completo en web', () {
      for (final section in BusinessSection.values) {
        expect(section.fullWidth, isTrue, reason: section.label);
      }
    });

    test('usa Reservas para rutas desconocidas', () {
      expect(BusinessSection.fromLocation('/otra'), BusinessSection.reservas);
    });
  });

  group('móvil (drawer)', () {
    testWidgets('el botón ☰ abre el menú con grupos y todas las opciones', (
      tester,
    ) async {
      await pumpShell(tester);
      expect(find.byType(BusinessSideMenu), findsNothing);

      await openMenu(tester);

      for (final group in BusinessSectionGroup.values) {
        expect(find.text(group.label.toUpperCase()), findsOneWidget);
      }
      for (final section in BusinessSection.values) {
        expect(menuItem(section.label), findsOneWidget);
      }
      expect(menuItem('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('marca la sección actual como seleccionada', (tester) async {
      await pumpShell(tester, initialLocation: AppRoutes.businessCourts);
      await openMenu(tester);

      expect(
        tester.getSemantics(menuItem('Canchas')),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          label: 'Canchas',
        ),
      );
    });

    testWidgets('elegir una opción navega, cierra el menú y no apila', (
      tester,
    ) async {
      await pumpShell(tester);
      await openMenu(tester);

      await tester.tap(menuItem('Mi negocio'));
      await tester.pumpAndSettle();

      expect(location(), AppRoutes.businessProfile);
      expect(find.text('Datos y ubicación de tu sede'), findsOneWidget);
      expect(find.byType(BusinessSideMenu), findsNothing);
      expect(router.canPop(), isFalse);
    });

    testWidgets('cerrar sesión pide confirmación y va al login de negocio', (
      tester,
    ) async {
      await pumpShell(tester);
      await openMenu(tester);

      await tester.tap(menuItem('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cerrar sesión?'), findsOneWidget);

      // Cancelar no navega ni cierra la sesión.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(location(), AppRoutes.businessClients);
      expect(signOuts, 0);

      await openMenu(tester);
      await tester.tap(menuItem('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cerrar sesión'),
        ),
      );
      await tester.pumpAndSettle();
      expect(signOuts, 1);
      expect(find.text('business-login-page'), findsOneWidget);
    });
  });

  group('escritorio (menú escondido)', () {
    const desktop = Size(1280, 800);

    testWidgets('el menú está escondido y se abre con ☰', (tester) async {
      await pumpShell(tester, size: desktop);
      expect(find.byType(BusinessSideMenu), findsNothing);

      await openMenu(tester);
      expect(find.byType(BusinessSideMenu), findsOneWidget);
    });

    testWidgets('elegir una opción navega y vuelve a esconder el menú', (
      tester,
    ) async {
      await pumpShell(tester, size: desktop);
      await openMenu(tester);

      await tester.tap(menuItem('Dashboard'));
      await tester.pumpAndSettle();

      expect(location(), AppRoutes.businessDashboard);
      expect(find.byType(BusinessSideMenu), findsNothing);
    });
  });

  for (final size in const [
    Size(320, 568),
    Size(412, 915),
    Size(800, 1280),
    Size(1280, 800),
  ]) {
    testWidgets('sin overflow en ${size.width}x${size.height}', (tester) async {
      await pumpShell(tester, size: size);
      await openMenu(tester);
      expect(tester.takeException(), isNull);
    });
  }

  group('solo lectura', () {
    testWidgets('sin plan activo muestra el aviso con acceso a Mi cuenta', (
      tester,
    ) async {
      await pumpShell(tester, canWrite: false);
      expect(
        find.text('Tu plan no está activo: solo puedes consultar información.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Ver mi plan'));
      await tester.pumpAndSettle();
      expect(location(), AppRoutes.businessSettings);
    });

    testWidgets('con plan activo no hay aviso', (tester) async {
      await pumpShell(tester);
      expect(find.text('Ver mi plan'), findsNothing);
    });
  });

  group('configuración inicial pendiente', () {
    Future<BusinessSetupGate> gateAt(SetupProgress progress) async {
      final storage = _MockStorage();
      when(() => storage.read()).thenAnswer(
        (_) async => const Session(
          accessToken: 'tok',
          role: 'ADMIN_NEGOCIO',
          displayName: 'Andrés',
        ),
      );
      final session = SessionManager(storage);
      await session.restore();
      final getProgress = _MockGetSetupProgress();
      when(
        () => getProgress(const NoParams()),
      ).thenAnswer((_) async => progress);
      final gate = BusinessSetupGate(getProgress, session);
      await gate.load();
      return gate;
    }

    testWidgets('muestra el paso y lo que falta del negocio', (tester) async {
      final gate = await tester.runAsync(
        () => gateAt(
          const SetupProgress(
            SetupStep.business,
            missing: [BusinessRequirement.location, BusinessRequirement.photo],
          ),
        ),
      );
      await pumpShell(
        tester,
        initialLocation: AppRoutes.businessProfile,
        setup: gate,
      );

      expect(find.text('Paso 1 de 2 · Completa tu negocio'), findsOneWidget);
      expect(
        find.text('Falta: ubicación en el mapa y al menos una foto.'),
        findsOneWidget,
      );
    });

    testWidgets('una sección bloqueada avisa y no navega', (tester) async {
      final gate = await tester.runAsync(
        () => gateAt(const SetupProgress(SetupStep.court)),
      );
      await pumpShell(
        tester,
        initialLocation: AppRoutes.businessCourts,
        setup: gate,
      );
      expect(find.text('Paso 2 de 2 · Registra tu primera cancha'), findsOne);

      await openMenu(tester);
      expect(find.bySemanticsLabel('Clientes (bloqueado)'), findsOneWidget);
      expect(find.bySemanticsLabel('Mi negocio'), findsOneWidget);
      await tester.tap(menuItem('Clientes'));
      await tester.pumpAndSettle();

      expect(location(), AppRoutes.businessCourts);
      expect(
        find.text('Primero registra una cancha lista para recibir reservas.'),
        findsOneWidget,
      );
    });
  });
}
