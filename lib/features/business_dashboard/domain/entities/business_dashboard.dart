import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/sport.dart';

/// Períodos del dashboard (`period` en la API).
enum DashboardPeriod {
  today('TODAY', 'Hoy'),
  last7Days('LAST_7_DAYS', '7 días'),
  last30Days('LAST_30_DAYS', '30 días'),
  thisMonth('THIS_MONTH', 'Este mes'),
  custom('CUSTOM', 'Personalizado');

  const DashboardPeriod(this.apiCode, this.label);

  final String apiCode;
  final String label;

  static DashboardPeriod fromApi(String? code) =>
      values.where((p) => p.apiCode == code).firstOrNull ?? today;
}

/// Filtros del dashboard. Con [DashboardPeriod.custom], [from] y [to] son
/// obligatorios (máximo 366 días).
class DashboardFilter extends Equatable {
  const DashboardFilter({
    this.period = DashboardPeriod.today,
    this.from,
    this.to,
    this.sport,
    this.courtId,
  });

  static const maxCustomDays = 366;

  final DashboardPeriod period;
  final DateTime? from;
  final DateTime? to;
  final Sport? sport;
  final String? courtId;

  DashboardFilter copyWith({
    DashboardPeriod? period,
    DateTime? Function()? from,
    DateTime? Function()? to,
    Sport? Function()? sport,
    String? Function()? courtId,
  }) => DashboardFilter(
    period: period ?? this.period,
    from: from != null ? from() : this.from,
    to: to != null ? to() : this.to,
    sport: sport != null ? sport() : this.sport,
    courtId: courtId != null ? courtId() : this.courtId,
  );

  @override
  List<Object?> get props => [period, from, to, sport, courtId];
}

/// Días de la semana tal como los envía la API (de lunes a domingo).
enum Weekday {
  monday('MONDAY', 'Lunes', 'Lun'),
  tuesday('TUESDAY', 'Martes', 'Mar'),
  wednesday('WEDNESDAY', 'Miércoles', 'Mié'),
  thursday('THURSDAY', 'Jueves', 'Jue'),
  friday('FRIDAY', 'Viernes', 'Vie'),
  saturday('SATURDAY', 'Sábado', 'Sáb'),
  sunday('SUNDAY', 'Domingo', 'Dom');

  const Weekday(this.apiCode, this.label, this.short);

  final String apiCode;
  final String label;
  final String short;

  static Weekday? fromApi(String? code) =>
      values.where((d) => d.apiCode == code).firstOrNull;
}

/// Valor del período, el del anterior y la variación en %. [changePct] es
/// `null` cuando el anterior fue 0 (se muestra "—").
class Trend extends Equatable {
  const Trend({required this.value, this.previous = 0, this.changePct});

  final num value;
  final num previous;
  final double? changePct;

  @override
  List<Object?> get props => [value, previous, changePct];
}

class CountAmount extends Equatable {
  const CountAmount({this.count = 0, this.amount = 0});

  final int count;
  final int amount;

  @override
  List<Object?> get props => [count, amount];
}

class DashboardPeriodInfo extends Equatable {
  const DashboardPeriodInfo({
    required this.type,
    required this.from,
    required this.to,
    required this.days,
    required this.previousFrom,
    required this.previousTo,
  });

  final DashboardPeriod type;
  final DateTime from;
  final DateTime to;
  final int days;
  final DateTime previousFrom;
  final DateTime previousTo;

  @override
  List<Object?> get props => [type, from, to, days, previousFrom, previousTo];
}

class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.reservations,
    this.confirmed = 0,
    this.completed = 0,
    this.noShow = 0,
    this.cancelled = 0,
    required this.collected,
    this.booked = 0,
    this.pendingBalance = 0,
    this.pendingPayments = const CountAmount(),
    required this.occupancyPct,
    this.bookedHours = 0,
    this.openHours = 0,
    this.averageTicket = 0,
    required this.newCustomers,
    this.cancellationRate = 0,
    this.noShowRate = 0,
    this.discounts = 0,
    this.refunds = const CountAmount(),
  });

  /// Reservas que empiezan en el período (incluidas canceladas).
  final Trend reservations;
  final int confirmed;
  final int completed;
  final int noShow;
  final int cancelled;

  /// Pagos aprobados recibidos en el período.
  final Trend collected;

  /// Valor de las reservas confirmadas y jugadas.
  final int booked;

  /// Lo que falta por cobrar de esas reservas.
  final int pendingBalance;

  /// Pagos por validar ahora mismo (no depende del período).
  final CountAmount pendingPayments;

  /// Horas reservadas ÷ horas abiertas, en %.
  final Trend occupancyPct;
  final num bookedHours;
  final num openHours;
  final int averageTicket;
  final Trend newCustomers;
  final num cancellationRate;
  final num noShowRate;
  final int discounts;
  final CountAmount refunds;

  @override
  List<Object?> get props => [
    reservations,
    confirmed,
    completed,
    noShow,
    cancelled,
    collected,
    booked,
    pendingBalance,
    pendingPayments,
    occupancyPct,
    bookedHours,
    openHours,
    averageTicket,
    newCustomers,
    cancellationRate,
    noShowRate,
    discounts,
    refunds,
  ];
}

class CourtOccupancy extends Equatable {
  const CourtOccupancy({
    required this.courtId,
    required this.name,
    this.sport,
    this.reservations = 0,
    this.bookedHours = 0,
    this.openHours = 0,
    this.occupancyPct = 0,
    this.booked = 0,
  });

  final String courtId;
  final String name;
  final Sport? sport;
  final int reservations;
  final num bookedHours;
  final num openHours;
  final num occupancyPct;
  final int booked;

  @override
  List<Object?> get props => [
    courtId,
    name,
    sport,
    reservations,
    bookedHours,
    openHours,
    occupancyPct,
    booked,
  ];
}

class WeekdayStat extends Equatable {
  const WeekdayStat({
    required this.day,
    this.reservations = 0,
    this.booked = 0,
  });

  final Weekday day;
  final int reservations;
  final int booked;

  @override
  List<Object?> get props => [day, reservations, booked];
}

class HeatmapCell extends Equatable {
  const HeatmapCell({
    required this.day,
    required this.hour,
    required this.reservations,
  });

  final Weekday day;

  /// Hora local de inicio, 0–23.
  final int hour;
  final int reservations;

  @override
  List<Object?> get props => [day, hour, reservations];
}

class TopCustomer extends Equatable {
  const TopCustomer({
    required this.id,
    required this.name,
    this.phone = '',
    this.reservations = 0,
    this.paid = 0,
  });

  final String id;
  final String name;
  final String phone;
  final int reservations;
  final int paid;

  @override
  List<Object?> get props => [id, name, phone, reservations, paid];
}

class PaymentMethodStat extends Equatable {
  const PaymentMethodStat({
    required this.code,
    required this.name,
    this.count = 0,
    this.amount = 0,
    this.pct = 0,
  });

  final String code;
  final String name;
  final int count;
  final int amount;

  /// % del total cobrado.
  final num pct;

  @override
  List<Object?> get props => [code, name, count, amount, pct];
}

class SportStat extends Equatable {
  const SportStat({
    required this.sport,
    this.reservations = 0,
    this.booked = 0,
  });

  final Sport sport;
  final int reservations;
  final int booked;

  @override
  List<Object?> get props => [sport, reservations, booked];
}

class TopProduct extends Equatable {
  const TopProduct({
    required this.name,
    this.productId,
    this.units = 0,
    this.amount = 0,
  });

  /// `null` si el producto ya no existe.
  final String? productId;
  final String name;
  final int units;
  final int amount;

  @override
  List<Object?> get props => [productId, name, units, amount];
}

class SalesDay extends Equatable {
  const SalesDay({required this.date, this.walkIn = 0, this.consumptions = 0});

  final DateTime date;
  final int walkIn;
  final int consumptions;

  int get total => walkIn + consumptions;

  @override
  List<Object?> get props => [date, walkIn, consumptions];
}

/// Ventas de productos del período (sin anuladas). Con filtro de deporte o
/// cancha solo cuentan los consumos de esas canchas.
class DashboardSales extends Equatable {
  const DashboardSales({
    this.total = const Trend(value: 0),
    this.walkIn = 0,
    this.consumptions = 0,
    this.count = 0,
    this.units = 0,
    this.averageConsumption = 0,
    this.pendingConsumptions = 0,
    this.topProducts = const [],
    this.byDay = const [],
  });

  /// Ventas sueltas + consumos cargados a reservas.
  final Trend total;

  /// Ventas sueltas, cobradas en el momento.
  final int walkIn;

  /// Consumos cargados a reservas (se cobran con la reserva).
  final int consumptions;
  final int count;
  final int units;

  /// Consumo promedio por reserva confirmada o jugada del período.
  final int averageConsumption;

  /// Parte del saldo pendiente que son consumos.
  final int pendingConsumptions;

  /// Los 5 que más dinero dejaron.
  final List<TopProduct> topProducts;

  /// Todos los días del período.
  final List<SalesDay> byDay;

  bool get isEmpty => count == 0 && pendingConsumptions == 0;

  @override
  List<Object?> get props => [
    total,
    walkIn,
    consumptions,
    count,
    units,
    averageConsumption,
    pendingConsumptions,
    topProducts,
    byDay,
  ];
}

/// `GET /business/dashboard`: todas las métricas del negocio en un período.
class BusinessDashboard extends Equatable {
  const BusinessDashboard({
    required this.period,
    this.currency = 'COP',
    required this.summary,
    this.occupancyByCourt = const [],
    this.byWeekday = const [],
    this.heatmap = const [],
    this.heatmapMax = 0,
    this.topCustomers = const [],
    this.paymentMethods = const [],
    this.bySport = const [],
    this.sales = const DashboardSales(),
  });

  final DashboardPeriodInfo period;
  final String currency;
  final DashboardSummary summary;
  final List<CourtOccupancy> occupancyByCourt;

  /// Siempre los 7 días, de lunes a domingo.
  final List<WeekdayStat> byWeekday;

  /// Solo las celdas con reservas.
  final List<HeatmapCell> heatmap;
  final int heatmapMax;
  final List<TopCustomer> topCustomers;

  /// De mayor a menor monto.
  final List<PaymentMethodStat> paymentMethods;
  final List<SportStat> bySport;

  /// Bebidas, snacks… vendidos en el período.
  final DashboardSales sales;

  /// Día con más reservas (`null` si no hubo ninguna).
  WeekdayStat? get busiestDay {
    WeekdayStat? best;
    for (final day in byWeekday) {
      if (day.reservations > (best?.reservations ?? 0)) best = day;
    }
    return best;
  }

  /// Franja (día y hora) con más reservas.
  HeatmapCell? get busiestSlot {
    HeatmapCell? best;
    for (final cell in heatmap) {
      if (cell.reservations > (best?.reservations ?? 0)) best = cell;
    }
    return best;
  }

  /// Horas con alguna reserva, de la primera a la última (para el mapa).
  (int, int)? get heatmapHours {
    if (heatmap.isEmpty) return null;
    var first = 23;
    var last = 0;
    for (final cell in heatmap) {
      if (cell.hour < first) first = cell.hour;
      if (cell.hour > last) last = cell.hour;
    }
    return (first, last);
  }

  int reservationsAt(Weekday day, int hour) =>
      heatmap
          .where((c) => c.day == day && c.hour == hour)
          .firstOrNull
          ?.reservations ??
      0;

  @override
  List<Object?> get props => [
    period,
    currency,
    summary,
    occupancyByCourt,
    byWeekday,
    heatmap,
    heatmapMax,
    topCustomers,
    paymentMethods,
    bySport,
    sales,
  ];
}
