part of 'payments_bloc.dart';

sealed class PaymentsEvent extends Equatable {
  const PaymentsEvent();

  @override
  List<Object?> get props => [];
}

/// Carga (o recarga tras crear un pago) el listado.
final class PaymentsRequested extends PaymentsEvent {
  const PaymentsRequested();
}

final class PaymentsTabChanged extends PaymentsEvent {
  const PaymentsTabChanged(this.tab);

  final PaymentStatus tab;

  @override
  List<Object?> get props => [tab];
}

final class PaymentApproved extends PaymentsEvent {
  const PaymentApproved(this.paymentId);

  final String paymentId;

  @override
  List<Object?> get props => [paymentId];
}

final class PaymentRejected extends PaymentsEvent {
  const PaymentRejected(this.paymentId, {this.reason});

  final String paymentId;
  final String? reason;

  @override
  List<Object?> get props => [paymentId, reason];
}
