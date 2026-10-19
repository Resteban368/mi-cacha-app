import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court.dart';
import 'package:mi_cancha/features/business_courts/domain/usecases/get_courts.dart';
import 'package:mi_cancha/features/business_dashboard/data/datasources/business_dashboard_api_data_source.dart';
import 'package:mi_cancha/features/business_dashboard/domain/entities/business_dashboard.dart';
import 'package:mi_cancha/features/business_dashboard/domain/entities/dashboard_failure.dart';
import 'package:mi_cancha/features/business_dashboard/domain/usecases/get_business_dashboard.dart';
import 'package:mi_cancha/features/business_dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'dashboard_fixtures.dart';

class _MockGetDashboard extends Mock implements GetBusinessDashboard {}

class _MockGetCourts extends Mock implements GetCourts {}

void main() {
  late _MockGetDashboard getDashboard;
  late _MockGetCourts getCourts;
  final dashboard = BusinessDashboardApiDataSource.fromJson(dashboardJson());

  const futbol = Court(
    id: 'c1',
    name: 'Sintética 1',
    sport: Sport.futbol,
    isActive: true,
    isComplete: true,
    isBookable: true,
  );
  const padel = Court(
    id: 'p1',
    name: 'Pádel 1',
    sport: Sport.padel,
    isActive: true,
    isComplete: true,
    isBookable: true,
  );

  setUpAll(() {
    registerFallbackValue(const DashboardFilter());
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    getDashboard = _MockGetDashboard();
    getCourts = _MockGetCourts();
    when(() => getDashboard(any())).thenAnswer((_) async => dashboard);
    when(() => getCourts(any())).thenAnswer((_) async => [futbol, padel]);
  });

  DashboardBloc build() =>
      DashboardBloc(getDashboard: getDashboard, getCourts: getCourts);

  blocTest<DashboardBloc, DashboardState>(
    'al empezar carga las canchas y las métricas de hoy',
    build: build,
    act: (b) => b.add(const DashboardStarted()),
    verify: (b) {
      expect(b.state.status, DashboardStatus.success);
      expect(b.state.dashboard, dashboard);
      expect(b.state.sports, [Sport.futbol, Sport.padel]);
      verify(() => getDashboard(const DashboardFilter())).called(1);
    },
  );

  blocTest<DashboardBloc, DashboardState>(
    'cambiar el período recarga y conserva el resultado anterior mientras',
    build: build,
    seed: () =>
        DashboardState(status: DashboardStatus.success, dashboard: dashboard),
    act: (b) => b.add(
      const DashboardFilterChanged(
        DashboardFilter(period: DashboardPeriod.last30Days),
      ),
    ),
    expect: () => [
      DashboardState(
        status: DashboardStatus.loading,
        filter: const DashboardFilter(period: DashboardPeriod.last30Days),
        dashboard: dashboard,
      ),
      DashboardState(
        status: DashboardStatus.success,
        filter: const DashboardFilter(period: DashboardPeriod.last30Days),
        dashboard: dashboard,
      ),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'gana el último filtro elegido',
    setUp: () {
      when(
        () => getDashboard(
          const DashboardFilter(period: DashboardPeriod.last7Days),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return dashboard;
      });
    },
    build: build,
    act: (b) => b
      ..add(
        const DashboardFilterChanged(
          DashboardFilter(period: DashboardPeriod.last7Days),
        ),
      )
      ..add(
        const DashboardFilterChanged(
          DashboardFilter(period: DashboardPeriod.thisMonth),
        ),
      ),
    wait: const Duration(milliseconds: 60),
    verify: (b) {
      expect(b.state.filter.period, DashboardPeriod.thisMonth);
      expect(b.state.status, DashboardStatus.success);
    },
  );

  blocTest<DashboardBloc, DashboardState>(
    'al cambiar a otro deporte se quita la cancha de otro deporte',
    build: build,
    seed: () => const DashboardState(
      status: DashboardStatus.success,
      courts: [futbol, padel],
      filter: DashboardFilter(courtId: 'c1'),
    ),
    act: (b) => b.add(
      const DashboardFilterChanged(
        DashboardFilter(courtId: 'c1', sport: Sport.padel),
      ),
    ),
    verify: (b) {
      expect(b.state.filter.courtId, isNull);
      expect(b.state.filterCourts, [padel]);
      verify(
        () => getDashboard(const DashboardFilter(sport: Sport.padel)),
      ).called(1);
    },
  );

  blocTest<DashboardBloc, DashboardState>(
    'error: guarda el motivo y permite reintentar',
    setUp: () => when(
      () => getDashboard(any()),
    ).thenThrow(const DashboardException(DashboardFailure.notAvailable)),
    build: build,
    act: (b) => b.add(const DashboardStarted()),
    verify: (b) {
      expect(b.state.status, DashboardStatus.failure);
      expect(b.state.failure, DashboardFailure.notAvailable);
    },
  );

  blocTest<DashboardBloc, DashboardState>(
    'si fallan las canchas, igual carga las métricas',
    setUp: () => when(() => getCourts(any())).thenThrow(Exception()),
    build: build,
    act: (b) => b.add(const DashboardStarted()),
    verify: (b) {
      expect(b.state.status, DashboardStatus.success);
      expect(b.state.courts, isEmpty);
    },
  );
}
