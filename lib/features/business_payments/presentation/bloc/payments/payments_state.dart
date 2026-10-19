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

/// Filtros del listado: cancha, medio de pago y día en que se recibió.
final class PaymentsFilter extends Equatable {
  const PaymentsFilter({this.court, this.method, this.day});

  final String? court;
  final PaymentMethod? method;
  final DateTime? day;

  bool get isActive => court != null || method != null || day != null;

  bool matches(Payment p) {
    if (court != null && p.courtName != court) return false;
    if (method != null && p.method != method) return false;
    final day = this.day;
    if (day != null) {
      final at = p.receivedAt;
      if (at.year != day.year || at.month != day.month || at.day != day.day) {
        return false;
      }
    }
    return true;
  }

  @override
  List<Object?> get props => [court, method, day];
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
