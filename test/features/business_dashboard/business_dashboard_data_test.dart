import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_dashboard/data/datasources/business_dashboard_api_data_source.dart';
import 'package:mi_cancha/features/business_dashboard/data/repositories/business_dashboard_repository_impl.dart';
import 'package:mi_cancha/features/business_dashboard/domain/entities/business_dashboard.dart';
import 'package:mi_cancha/features/business_dashboard/domain/entities/dashboard_failure.dart';
import 'package:mi_cancha/features/business_dashboard/domain/usecases/get_business_dashboard.dart';

import '../../helpers/api_dio.dart';
import '../../helpers/fake_http_adapter.dart';
import 'dashboard_fixtures.dart';

void main() {
  late FakeHttpAdapter adapter;
  late BusinessDashboardApiDataSource source;

  setUp(() {
    adapter = FakeHttpAdapter((_) => (200, dashboardJson()));
    source = BusinessDashboardApiDataSource(apiDio(adapter));
  });

  test('pide el período y los filtros; lee todas las métricas', () async {
    final d = await source.getDashboard(
      const DashboardFilter(
        period: DashboardPeriod.last7Days,
        sport: Sport.futbol,
        courtId: 'c1',
      ),
    );

    final request = adapter.requests.single;
    expect(request.path, '/business/dashboard');
    expect(request.queryParameters, {
      'period': 'LAST_7_DAYS',
      'sport': 'FUTBOL',
      'courtId': 'c1',
    });

    expect(d.period.type, DashboardPeriod.last7Days);
    expect(d.period.from, DateTime(2026, 10, 9));
    expect(d.period.previousTo, DateTime(2026, 10, 8));
    expect(d.summary.reservations.value, 10);
    expect(d.summary.collected.changePct, -20);
    // Período anterior en 0: sin porcentaje.
    expect(d.summary.occupancyPct.changePct, isNull);
    expect(d.summary.pendingPayments.count, 2);
    expect(d.summary.refunds.amount, 50000);
    expect(d.occupancyByCourt.single.sport, Sport.futbol);
    // Los 7 días, ordenados de lunes a domingo.
    expect(d.byWeekday.map((w) => w.day), Weekday.values);
    expect(d.busiestDay!.day, Weekday.thursday);
    expect(d.busiestSlot!.hour, 19);
    expect(d.heatmapHours, (8, 20));
    expect(d.reservationsAt(Weekday.friday, 20), 2);
    expect(d.reservationsAt(Weekday.friday, 9), 0);
    expect(d.topCustomers.single.paid, 200000);
    expect(d.paymentMethods.first.name, 'Nequi');
    expect(d.bySport.map((s) => s.sport), [Sport.futbol, Sport.padel]);
  });

  test('con CUSTOM envía from y to; sin filtros solo el período', () async {
    await source.getDashboard(
      DashboardFilter(
        period: DashboardPeriod.custom,
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      ),
    );
    await source.getDashboard(const DashboardFilter());

    expect(adapter.requests.first.queryParameters, {
      'period': 'CUSTOM',
      'from': '2026-09-01',
      'to': '2026-09-30',
    });
    expect(adapter.requests.last.queryParameters, {'period': 'TODAY'});
  });

  test('respuesta vacía no rompe la lectura', () {
    final d = BusinessDashboardApiDataSource.fromJson({});
    expect(d.summary.reservations.value, 0);
    expect(d.busiestDay, isNull);
    expect(d.heatmapHours, isNull);
    expect(d.sales.isEmpty, isTrue);
    expect(d.sales.byDay, isEmpty);
  });

  test('lee las ventas de productos', () {
    final d = BusinessDashboardApiDataSource.fromJson(dashboardJson());
    expect(d.sales.total.value, 200000);
    expect(d.sales.consumptions, 150000);
    expect(d.sales.pendingConsumptions, 40000);
    expect(d.sales.topProducts.last.productId, isNull);
    expect(d.sales.byDay, hasLength(7));
    expect(d.sales.byDay[5].date, DateTime(2026, 10, 14));
    expect(d.sales.byDay[5].total, 120000);
  });

  group('errores', () {
    Future<DashboardException> failWith(int status, Object body) async {
      adapter.handler = (_) => (status, body);
      try {
        await BusinessDashboardRepositoryImpl(
          source,
        ).getDashboard(const DashboardFilter());
      } on DashboardException catch (e) {
        return e;
      }
      fail('debía fallar');
    }

    test('404: aún no está desplegado', () async {
      final e = await failWith(404, {'message': 'Cannot GET'});
      expect(e.failure, DashboardFailure.notAvailable);
    });

    test('400: período inválido con el mensaje', () async {
      final e = await failWith(400, {
        'message': 'El período no puede superar 366 días',
      });
      expect(e.failure, DashboardFailure.invalid);
      expect(e.message, 'El período no puede superar 366 días');
    });

    test('sin conexión', () async {
      adapter.handler = offline;
      try {
        await BusinessDashboardRepositoryImpl(
          source,
        ).getDashboard(const DashboardFilter());
        fail('debía fallar');
      } on DashboardException catch (e) {
        expect(e.failure, DashboardFailure.network);
      }
    });
  });

  group('validación del período personalizado', () {
    test('exige fechas, en orden y hasta 366 días', () {
      expect(
        GetBusinessDashboard.validate(
          const DashboardFilter(period: DashboardPeriod.custom),
        ),
        isNotNull,
      );
      expect(
        GetBusinessDashboard.validate(
          DashboardFilter(
            period: DashboardPeriod.custom,
            from: DateTime(2026, 10, 10),
            to: DateTime(2026, 10, 1),
          ),
        ),
        contains('anterior'),
      );
      expect(
        GetBusinessDashboard.validate(
          DashboardFilter(
            period: DashboardPeriod.custom,
            from: DateTime(2025, 1, 1),
            to: DateTime(2026, 1, 2),
          ),
        ),
        contains('366'),
      );
      expect(
        GetBusinessDashboard.validate(
          DashboardFilter(
            period: DashboardPeriod.custom,
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 12, 31),
          ),
        ),
        isNull,
      );
      expect(GetBusinessDashboard.validate(const DashboardFilter()), isNull);
    });
  });
}
