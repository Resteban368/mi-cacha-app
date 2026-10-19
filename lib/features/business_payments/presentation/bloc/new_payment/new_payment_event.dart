part of 'new_payment_bloc.dart';

enum PaymentTargetMode { customer, reservation, newCustomer }

sealed class NewPaymentEvent extends Equatable {
  const NewPaymentEvent();

  @override
  List<Object?> get props => [];
}

final class NewPaymentStarted extends NewPaymentEvent {
  const NewPaymentStarted();
}

final class NewPaymentTargetModeChanged extends NewPaymentEvent {
  const NewPaymentTargetModeChanged(this.mode);

  final PaymentTargetMode mode;

  @override
  List<Object?> get props => [mode];
}

final class NewPaymentCustomerSearchChanged extends NewPaymentEvent {
  const NewPaymentCustomerSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Pide la página siguiente de clientes al acercarse al final de la lista.
final class NewPaymentCustomersNextPage extends NewPaymentEvent {
  const NewPaymentCustomersNextPage();
}

final class NewPaymentCustomerSelected extends NewPaymentEvent {
  const NewPaymentCustomerSelected(this.customer);

  final Customer? customer;

  @override
  List<Object?> get props => [customer];
}

final class NewPaymentReservationSearchChanged extends NewPaymentEvent {
  const NewPaymentReservationSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class NewPaymentReservationSelected extends NewPaymentEvent {
  const NewPaymentReservationSelected(this.reservation);

  final Reservation? reservation;

  @override
  List<Object?> get props => [reservation];
}

final class NewPaymentSubmitted extends NewPaymentEvent {
  const NewPaymentSubmitted(this.payment);

  final NewPayment payment;

  @override
  List<Object?> get props => [payment];
}
