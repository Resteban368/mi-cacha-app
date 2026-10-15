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

final class PaymentsState extends Equatable {
  const PaymentsState({
    this.status = PaymentsStatus.initial,
    this.payments = const [],
    this.tab = PaymentStatus.pending,
    this.processing = const {},
    this.notice,
  });

  final PaymentsStatus status;
  final List<Payment> payments;
  final PaymentStatus tab;

  /// Pagos con una validación en curso (deshabilita sus botones).
  final Set<String> processing;
  final PaymentsNotice? notice;

  List<Payment> get visible =>
      payments.where((p) => p.status == tab).toList(growable: false);

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
    Set<String>? processing,
    PaymentsNotice? notice,
  }) => PaymentsState(
    status: status ?? this.status,
    payments: payments ?? this.payments,
    tab: tab ?? this.tab,
    processing: processing ?? this.processing,
    notice: notice ?? this.notice,
  );

  @override
  List<Object?> get props => [status, payments, tab, processing, notice];
}
