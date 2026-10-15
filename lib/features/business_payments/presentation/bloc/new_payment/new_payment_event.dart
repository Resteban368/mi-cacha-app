part of 'new_payment_bloc.dart';

sealed class NewPaymentEvent extends Equatable {
  const NewPaymentEvent();

  @override
  List<Object?> get props => [];
}

final class NewPaymentSubmitted extends NewPaymentEvent {
  const NewPaymentSubmitted(this.payment);

  final NewPayment payment;

  @override
  List<Object?> get props => [payment];
}
