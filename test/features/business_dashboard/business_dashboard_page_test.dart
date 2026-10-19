import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court.dart';
import 'package:mi_cancha/features/business_dashboard/data/datasources/business_dashboard_api_data_source.dart';
import 'package:mi_cancha/features/business_dashboard/domain/entities/business_dashboard.dart';
import 'package:mi_cancha/features/business_dashboard/domain/entities/dashboard_failure.dart';
import 'package:mi_cancha/features/business_dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:mi_cancha/features/business_dashboard/presentation/pages/business_dashboard_page.dart';
import 'package:mocktail/mocktail.dart';

import 'dashboard_fixtures.dart';

class _MockBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const DashboardStarted());
  });

  late _MockBloc bloc;
  setUp(() => bloc = _MockBloc());

  final dashboard = BusinessDashboardApiDataSource.fromJson(dashboardJson());
  final ready = DashboardState(
    status: DashboardStatus.success,
    filter: const DashboardFilter(period: DashboardPeriod.last7Days),
    dashboard: dashboard,
    courts: const [
      Court(
        id: 'c1',
        name: 'Sintética 1',
        sport: Sport.futbol,
        isActive: true,
        isComplete: true,
        isBookable: true,
      ),
      Court(
        id: 'p1',
        name: 'Pádel 1',
        sport: Sport.padel,
        isActive: true,
        isComplete: true,
        isBookable: true,
      ),
    ],
  );

  Future<void> pump(
    WidgetTester tester,
    DashboardState state, {
    Size size = const Size(390, 3600),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    whenListen(bloc, const Stream<DashboardState>.empty(), initialState: state);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<DashboardBloc>.value(
            value: bloc,
            child: const BusinessDashboardPage(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('muestra indicadores, variaciones y todas las secciones', (
    tester,
  ) async {
    await pump(tester, ready);

    expect(find.text('10'), findsWidgets); // reservas
    expect(find.text('25 %'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsWidgets);
    expect(find.text(r'$400.000'), findsWidgets); // cobrado
    expect(find.text('20 %'), findsWidgets);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    // Ocupación sin período anterior: "—".
    expect(find.text('—'), findsOneWidget);
    expect(find.text('14 de 70 h abiertas'), findsOneWidget);
    expect(find.byKey(const Key('dashboard-period')), findsOneWidget);
    expect(find.text('Días con más movimiento'), findsOneWidget);
    expect(find.text('El jueves es el día con más reservas'), findsOneWidget);
    expect(
      find.textContaining('Hora pico: jueves a las 7:00 p. m.'),
      findsOneWidget,
    );
    expect(find.text('Laura Gómez'), findsOneWidget);
    expect(
      find.text('Nequi es la plataforma con más pagos (75 %)'),
      findsOneWidget,
    );
    expect(find.text('Sintética 1'), findsOneWidget);
    expect(find.text('Reservas por deporte'), findsOneWidget);
  });

  testWidgets('elegir un período lo pide al bloc', (tester) async {
    await pump(tester, ready);
    await tester.tap(find.byKey(const Key('period-THIS_MONTH')));
    verify(
      () => bloc.add(
        const DashboardFilterChanged(
          DashboardFilter(period: DashboardPeriod.thisMonth),
        ),
      ),
    ).called(1);
  });

  testWidgets('filtra por deporte desde el menú', (tester) async {
    await pump(tester, ready);
    await tester.tap(find.byKey(const Key('filter-sport')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pádel').last);
    await tester.pumpAndSettle();
    verify(
      () => bloc.add(
        const DashboardFilterChanged(
          DashboardFilter(
            period: DashboardPeriod.last7Days,
            sport: Sport.padel,
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('sin el endpoint desplegado lo explica y permite reintentar', (
    tester,
  ) async {
    await pump(
      tester,
      const DashboardState(
        status: DashboardStatus.failure,
        failure: DashboardFailure.notAvailable,
      ),
    );
    expect(find.text('El dashboard aún no está disponible'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dashboard-retry')));
    verify(() => bloc.add(const DashboardRefreshed())).called(1);
  });

  testWidgets('período sin datos muestra los vacíos', (tester) async {
    await pump(
      tester,
      DashboardState(
        status: DashboardStatus.success,
        dashboard: BusinessDashboardApiDataSource.fromJson({}),
      ),
    );
    expect(find.text('Sin reservas en este período'), findsWidgets);
    expect(find.text('Sin pagos aprobados en este período'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [
    Size(320, 4200),
    Size(768, 3000),
    Size(1440, 2000),
  ]) {
    testWidgets('sin desbordes en ${size.width.toInt()} px', (tester) async {
      await pump(tester, ready, size: size);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('en una ventana mediana ya usa el diseño de escritorio', (
    tester,
  ) async {
    await pump(tester, ready, size: const Size(900, 2400));
    // 4 indicadores por fila y secciones lado a lado.
    final reservas = tester.getTopLeft(
      find.byKey(const Key('kpi-reservations')),
    );
    final ticket = tester.getTopLeft(find.byKey(const Key('kpi-ticket')));
    expect(ticket.dy, reservas.dy);
    final estado = tester.getTopLeft(find.text('Estado de las reservas'));
    final metodos = tester.getTopLeft(find.text('Métodos de pago'));
    expect(metodos.dy, estado.dy);
    expect(metodos.dx, greaterThan(estado.dx));
    expect(tester.takeException(), isNull);
  });
}
