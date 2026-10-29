part of 'payments_bloc.dart';

enum PaymentsStatus { initial, loading, success, failure }

/// Mensaje puntual para la UI (snackbar). [id] distingue mensajes iguales.
final class PaymentsNotice extends Equatable {
  const PaymentsNotice(this.id, this.message, {this.isError = false});

  final int id;
  final String message;
  final bool isError;

  @override
  List<Object?> get props => [id, message, isError];
}

/// Filtros del listado: cancha, medio de pago y rango de días en que se
/// recibió (ambos días incluidos).
final class PaymentsFilter extends Equatable {
  const PaymentsFilter({this.court, this.method, this.from, this.to});

  final String? court;
  final PaymentMethod? method;
  final DateTime? from;
  final DateTime? to;

  bool get isActive =>
      court != null || method != null || from != null || to != null;

  bool get hasDates => from != null || to != null;

  bool matches(Payment p) {
    if (court != null && p.courtName != court) return false;
    if (method != null && p.method != method) return false;
    final at = DateTime(
      p.receivedAt.year,
      p.receivedAt.month,
      p.receivedAt.day,
    );
    if (from case final from? when at.isBefore(_day(from))) return false;
    if (to case final to? when at.isAfter(_day(to))) return false;
    return true;
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  PaymentsFilter copyWith({
    String? Function()? court,
    PaymentMethod? Function()? method,
    DateTime? Function()? from,
    DateTime? Function()? to,
  }) => PaymentsFilter(
    court: court != null ? court() : this.court,
    method: method != null ? method() : this.method,
    from: from != null ? from() : this.from,
    to: to != null ? to() : this.to,
  );

  @override
  List<Object?> get props => [court, method, from, to];
}

/// Totales de los pagos que se ven con la pestaña y los filtros.
final class PaymentsSummary extends Equatable {
  const PaymentsSummary({
    this.count = 0,
    this.total = 0,
    this.byMethod = const [],
    this.courts = 0,
    this.consumptions = 0,
    this.walkIn = 0,
  });

  factory PaymentsSummary.of(List<Payment> payments) {
    final byMethod = <PaymentMethod, int>{};
    var courts = 0, consumptions = 0, walkIn = 0, total = 0;
    for (final p in payments) {
      total += p.amount;
      byMethod[p.method] = (byMethod[p.method] ?? 0) + p.amount;
      if (p.isWalkInSale) {
        walkIn += p.amount;
      } else {
        courts += p.courtAmount;
        consumptions += p.productsAmount;
      }
    }
    return PaymentsSummary(
      count: payments.length,
      total: total,
      byMethod: byMethod.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
      courts: courts,
      consumptions: consumptions,
      walkIn: walkIn,
    );
  }

  final int count;
  final int total;

  /// Total por medio de pago, de mayor a menor.
  final List<MapEntry<PaymentMethod, int>> byMethod;

  /// Lo que fue para canchas, para consumos de reservas y para ventas de
  /// mostrador. Suman [total].
  final int courts;
  final int consumptions;
  final int walkIn;

  @override
  List<Object?> get props => [
    count,
    total,
    byMethod,
    courts,
    consumptions,
    walkIn,
  ];
}

final class PaymentsState extends Equatable {
  const PaymentsState({
    this.status = PaymentsStatus.initial,
    this.payments = const [],
    this.tab = PaymentStatus.approved,
    this.filter = const PaymentsFilter(),
    this.processing = const {},
    this.notice,
  });

  final PaymentsStatus status;
  final List<Payment> payments;
  final PaymentStatus tab;
  final PaymentsFilter filter;

  /// Pagos con una validación en curso (deshabilita sus botones).
  final Set<String> processing;
  final PaymentsNotice? notice;

  List<Payment> get visible => payments
      .where((p) => p.status == tab && filter.matches(p))
      .toList(growable: false);

  PaymentsSummary get summary => PaymentsSummary.of(visible);

  /// Canchas con pagos en la pestaña actual (opciones del filtro).
  List<String> get courtOptions => {
    for (final p in payments)
      if (p.status == tab && p.courtName != null) p.courtName!,
  }.toList()..sort();

  /// Medios de pago con pagos en la pestaña actual (opciones del filtro).
  List<PaymentMethod> get methodOptions => [
    for (final m in PaymentMethod.values)
      if (payments.any((p) => p.status == tab && p.method == m)) m,
  ];

  int countFor(PaymentStatus status) =>
      payments.where((p) => p.status == status).length;

  /// Total pendiente de validar, en COP.
  int get pendingAmount => payments
      .where((p) => p.status == PaymentStatus.pending)
      .fold(0, (sum, p) => sum + p.amount);

  PaymentsState copyWith({
    PaymentsStatus? status,
    List<Payment>? payments,
    PaymentStatus? tab,
    PaymentsFilter? filter,
    Set<String>? processing,
    PaymentsNotice? notice,
  }) => PaymentsState(
    status: status ?? this.status,
    payments: payments ?? this.payments,
    tab: tab ?? this.tab,
    filter: filter ?? this.filter,
    processing: processing ?? this.processing,
    notice: notice ?? this.notice,
  );

  @override
  List<Object?> get props => [
    status,
    payments,
    tab,
    filter,
    processing,
    notice,
  ];
}
