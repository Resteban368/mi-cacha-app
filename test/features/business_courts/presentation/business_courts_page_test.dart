import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/core/router/app_routes.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court.dart';
import 'package:mi_cancha/features/business_courts/presentation/bloc/courts_bloc.dart';
import 'package:mi_cancha/features/business_courts/presentation/pages/business_courts_page.dart';
import 'package:mi_cancha/features/business_courts/presentation/widgets/court_list_card.dart';
import 'package:mocktail/mocktail.dart';

import '../court_fixtures.dart';

class _MockBloc extends MockBloc<CourtsEvent, CourtsState>
    implements CourtsBloc {}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late _MockBloc bloc;
  late GoRouter router;
  setUp(() => bloc = _MockBloc());

  const incomplete = Court(
    id: 'c2',
    name: 'Cancha 2',
    sport: Sport.futbol,
    isActive: true,
    isComplete: false,
    isBookable: false,
    photos: {CourtPhotoSlot.main: 'https://api.test/x.jpg'},
  );
  const inactive = Court(
    id: 'c3',
    name: 'Cancha 3',
    sport: Sport.voleibol,
    isActive: false,
    isComplete: true,
    isBookable: false,
  );

  Future<void> pump(
    WidgetTester tester,
    CourtsState state, {
    Size size = const Size(390, 844),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    whenListen(bloc, const Stream<CourtsState>.empty(), initialState: state);
    router = GoRouter(
      initialLocation: AppRoutes.businessCourts,
      routes: [
        GoRoute(
          path: AppRoutes.businessCourts,
          builder: (_, _) => Scaffold(
            body: BlocProvider<CourtsBloc>.value(
              value: bloc,
              child: const BusinessCourtsPage(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.businessEditCourt,
          builder: (_, state) =>
              Scaffold(body: Text('edit-court ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: AppRoutes.businessNewCourt,
          builder: (_, state) => Scaffold(
            body: Text('new-court ${state.uri.queryParameters['copiar']}'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
  }

  final ready = CourtsState(
    status: CourtsStatus.ready,
    courts: [padelCourt, incomplete, inactive],
  );

  testWidgets('muestra cada cancha con su estado, horario y precio', (
    tester,
  ) async {
    await pump(tester, ready, size: const Size(390, 1400));

    expect(find.text('Mis canchas'), findsOneWidget);
    expect(find.text('3 canchas · 1 lista para reservas'), findsOneWidget);
    expect(find.text('Cancha Central Pádel 1'), findsOneWidget);
    expect(find.text('Pádel · Cubierta'), findsOneWidget);
    expect(find.text('Lista para reservas'), findsOneWidget);
    expect(find.text('Faltan 2 fotos'), findsOneWidget);
    expect(find.text('Inactiva'), findsOneWidget);
    expect(find.text('Lun a Sáb · horarios variados'), findsOneWidget);
    expect(find.text(r'$89.900/h · turnos de 1 h 30'), findsOneWidget);
    expect(find.text('2 tarifas por franja'), findsOneWidget);
  });

  testWidgets('"Usar como base" abre una cancha nueva copiando de esa', (
    tester,
  ) async {
    await pump(tester, ready);
    await tester.tap(find.text('Usar como base').first);
    await tester.pumpAndSettle();
    expect(find.text('new-court c-padel'), findsOneWidget);
  });

  testWidgets('"Editar" abre la cancha en el formulario', (tester) async {
    await pump(tester, ready);
    await tester.tap(find.byKey(const Key('edit-court-c-padel')));
    await tester.pumpAndSettle();
    expect(find.text('edit-court c-padel'), findsOneWidget);
  });

  testWidgets('"Nueva cancha" abre el formulario vacío', (tester) async {
    await pump(tester, ready);
    await tester.tap(find.byKey(const Key('new-court')));
    await tester.pumpAndSettle();
    expect(find.text('new-court null'), findsOneWidget);
  });

  testWidgets('sin canchas invita a crear la primera', (tester) async {
    await pump(tester, const CourtsState(status: CourtsStatus.ready));
    expect(find.text('Aún no tienes canchas'), findsOneWidget);
    await tester.tap(find.text('Crear mi primera cancha'));
    await tester.pumpAndSettle();
    expect(find.text('new-court null'), findsOneWidget);
  });

  testWidgets('error al cargar permite reintentar', (tester) async {
    await pump(tester, const CourtsState(status: CourtsStatus.failure));
    await tester.tap(find.text('Reintentar'));
    verify(() => bloc.add(const CourtsRequested())).called(1);
  });

  testWidgets('web: tarjetas en varias columnas', (tester) async {
    await pump(tester, ready, size: const Size(1280, 900));
    final first = tester.getTopLeft(find.byType(CourtListCard).at(0));
    final second = tester.getTopLeft(find.byType(CourtListCard).at(1));
    expect(second.dy, first.dy);
    expect(second.dx, greaterThan(first.dx));
  });

  for (final size in const [
    Size(320, 568),
    Size(412, 915),
    Size(900, 700),
    Size(1440, 900),
  ]) {
    testWidgets('sin overflow en ${size.width}x${size.height}', (tester) async {
      await pump(tester, ready, size: size);
      expect(tester.takeException(), isNull);
    });
  }
}
