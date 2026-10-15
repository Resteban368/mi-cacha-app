import 'package:equatable/equatable.dart';

import 'customer.dart';

/// Pago que se registra al reservar.
class NewPayment extends Equatable {
  const NewPayment({
    required this.amount,
    required this.method,
    this.reference,
    this.note,
  });

  /// COP; mayor que 0 y sin superar el total.
  final int amount;

  /// `code` del catálogo de métodos de pago (p. ej. `NEQUI`).
  final String method;
  final String? reference;
  final String? note;

  @override
  List<Object?> get props => [amount, method, reference, note];
}

/// Datos para crear una reserva (entrada del caso de uso).
class NewReservation extends Equatable {
  const NewReservation({
    required this.courtId,
    required this.start,
    required this.slots,
    this.customerId,
    this.customer,
    this.customerDetail,
    this.contactNote,
    this.tag,
    this.isRecurring = false,
    this.discount = 0,
    this.payment,
  }) : assert(
         (customerId == null) != (customer == null),
         'Envía customerId o customer, uno de los dos',
       );

  static const maxSlots = 5;
  static const maxDetail = 100;
  static const maxContactNote = 200;
  static const maxTag = 30;

  final String courtId;

  /// `start` del turno tal como llegó de la disponibilidad.
  final String start;
  final int slots;
  final String? customerId;
  final NewCustomer? customer;
  final String? customerDetail;
  final String? contactNote;
  final String? tag;
  final bool isRecurring;
  final int discount;
  final NewPayment? payment;

  @override
  List<Object?> get props => [
    courtId,
    start,
    slots,
    customerId,
    customer,
    customerDetail,
    contactNote,
    tag,
    isRecurring,
    discount,
    payment,
  ];
}
