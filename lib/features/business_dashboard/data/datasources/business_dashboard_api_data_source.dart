import 'package:dio/dio.dart';

import '../../../../core/domain/entities/sport.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/business_dashboard.dart';

abstract interface class BusinessDashboardDataSource {
  Future<BusinessDashboard> getDashboard(DashboardFilter filter);
}

/// `GET /business/dashboard`: métricas del negocio calculadas en el servidor.
class BusinessDashboardApiDataSource implements BusinessDashboardDataSource {
  const BusinessDashboardApiDataSource(this._dio);

  final Dio _dio;

  @override
  Future<BusinessDashboard> getDashboard(DashboardFilter filter) async {
    final response = await apiCall(
      () => _dio.get<Map<String, dynamic>>(
        '/business/dashboard',
        queryParameters: queryOf(filter),
      ),
    );
    return fromJson(response.data!);
  }

  static Map<String, dynamic> queryOf(DashboardFilter filter) => {
    'period': filter.period.apiCode,
    if (filter.period == DashboardPeriod.custom) ...{
      if (filter.from case final from?) 'from': dayParam(from),
      if (filter.to case final to?) 'to': dayParam(to),
    },
    'sport': ?filter.sport?.apiCode,
    'courtId': ?filter.courtId,
  };

  /// `2026-10-14`: el día calendario que se ve en la app.
  static String dayParam(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static DateTime _date(Object? value) {
    final text = value as String? ?? '';
    final parts = text.split('-').map(int.tryParse).toList();
    if (parts.length == 3 && !parts.contains(null)) {
      return DateTime(parts[0]!, parts[1]!, parts[2]!);
    }
    return DateTime.tryParse(text)?.toLocal() ?? DateTime(1970);
  }

  static int _int(Object? value) => (value as num? ?? 0).round();

  static num _num(Object? value) => value as num? ?? 0;

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : const {};

  static List<Map<String, dynamic>> _list(Object? value) => value is List
      ? value.whereType<Map<String, dynamic>>().toList()
      : const [];

  static Trend _trend(Object? value) {
    final json = _map(value);
    return Trend(
      value: _num(json['value']),
      previous: _num(json['previous']),
      changePct: (json['changePct'] as num?)?.toDouble(),
    );
  }

  static CountAmount _countAmount(Object? value) {
    final json = _map(value);
    return CountAmount(
      count: _int(json['count']),
      amount: _int(json['amount']),
    );
  }

  /// Sin `sales` (API anterior a las ventas) queda todo en cero.
  static DashboardSales _sales(Object? value) {
    final json = _map(value);
    return DashboardSales(
      total: _trend(json['total']),
      walkIn: _int(json['walkIn']),
      consumptions: _int(json['consumptions']),
      count: _int(json['count']),
      units: _int(json['units']),
      averageConsumption: _int(json['averageConsumption']),
      pendingConsumptions: _int(json['pendingConsumptions']),
      topProducts: [
        for (final p in _list(json['topProducts']))
          TopProduct(
            productId: p['productId'] as String?,
            name: p['name'] as String? ?? '',
            units: _int(p['units']),
            amount: _int(p['amount']),
          ),
      ],
      byDay: [
        for (final d in _list(json['byDay']))
          SalesDay(
            date: _date(d['date']),
            walkIn: _int(d['walkIn']),
            consumptions: _int(d['consumptions']),
          ),
      ],
    );
  }

  static BusinessDashboard fromJson(Map<String, dynamic> json) {
    final period = _map(json['period']);
    final summary = _map(json['summary']);
    return BusinessDashboard(
      period: DashboardPeriodInfo(
        type: DashboardPeriod.fromApi(period['type'] as String?),
        from: _date(period['from']),
        to: _date(period['to']),
        days: _int(period['days']),
        previousFrom: _date(period['previousFrom']),
        previousTo: _date(period['previousTo']),
      ),
      currency: json['currency'] as String? ?? 'COP',
      summary: DashboardSummary(
        reservations: _trend(summary['reservations']),
        confirmed: _int(summary['confirmed']),
        completed: _int(summary['completed']),
        noShow: _int(summary['noShow']),
        cancelled: _int(summary['cancelled']),
        collected: _trend(summary['collected']),
        booked: _int(summary['booked']),
        pendingBalance: _int(summary['pendingBalance']),
        pendingPayments: _countAmount(summary['pendingPayments']),
        occupancyPct: _trend(summary['occupancyPct']),
        bookedHours: _num(summary['bookedHours']),
        openHours: _num(summary['openHours']),
        averageTicket: _int(summary['averageTicket']),
        newCustomers: _trend(summary['newCustomers']),
        cancellationRate: _num(summary['cancellationRate']),
        noShowRate: _num(summary['noShowRate']),
        discounts: _int(summary['discounts']),
        refunds: _countAmount(summary['refunds']),
      ),
      occupancyByCourt: [
        for (final c in _list(json['occupancyByCourt']))
          CourtOccupancy(
            courtId: c['courtId'] as String? ?? '',
            name: c['name'] as String? ?? '',
            sport: Sport.fromApi(c['sport'] as String?),
            reservations: _int(c['reservations']),
            bookedHours: _num(c['bookedHours']),
            openHours: _num(c['openHours']),
            occupancyPct: _num(c['occupancyPct']),
            booked: _int(c['booked']),
          ),
      ],
      byWeekday: [
        for (final d in _list(json['byWeekday']))
          if (Weekday.fromApi(d['dayOfWeek'] as String?) case final day?)
            WeekdayStat(
              day: day,
              reservations: _int(d['reservations']),
              booked: _int(d['booked']),
            ),
      ]..sort((a, b) => a.day.index.compareTo(b.day.index)),
      heatmap: [
        for (final h in _list(json['heatmap']))
          if (Weekday.fromApi(h['dayOfWeek'] as String?) case final day?)
            HeatmapCell(
              day: day,
              hour: _int(h['hour']),
              reservations: _int(h['reservations']),
            ),
      ],
      heatmapMax: _int(json['heatmapMax']),
      topCustomers: [
        for (final c in _list(json['topCustomers']))
          TopCustomer(
            id: c['id'] as String? ?? '',
            name: c['name'] as String? ?? '',
            phone: c['phone'] as String? ?? '',
            reservations: _int(c['reservations']),
            paid: _int(c['paid']),
          ),
      ],
      paymentMethods: [
        for (final m in _list(json['paymentMethods']))
          PaymentMethodStat(
            code: m['code'] as String? ?? '',
            name: m['name'] as String? ?? m['code'] as String? ?? '',
            count: _int(m['count']),
            amount: _int(m['amount']),
            pct: _num(m['pct']),
          ),
      ],
      bySport: [
        for (final s in _list(json['bySport']))
          if (Sport.fromApi(s['sport'] as String?) case final sport?)
            SportStat(
              sport: sport,
              reservations: _int(s['reservations']),
              booked: _int(s['booked']),
            ),
      ],
      sales: _sales(json['sales']),
      salesEnabled: json['salesEnabled'] as bool? ?? false,
    );
  }
}
