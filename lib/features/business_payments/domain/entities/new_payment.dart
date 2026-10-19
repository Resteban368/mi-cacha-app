import 'package:equatable/equatable.dart';

import 'payment.dart';

/// Datos para registrar un pago manualmente desde el negocio.
class NewPayment extends Equatable {
  const NewPayment({
    required this.customerName,
    required this.amount,
    required this.method,
    required this.concept,
    this.customerId,
    this.reservationId,
    this.courtName,
    this.reservationStart,
    this.reference,
    this.note,
  });

  final String customerName;
  final int amount;
  final PaymentMethod method;
  final PaymentConcept concept;
  final String? customerId;
  final String? reservationId;
  final String? courtName;
  final DateTime? reservationStart;
  final String? reference;
  final String? note;

  /// Si el medio de pago pide referencia bancaria / comprobante (opcional).
  static bool requiresReference(PaymentMethod method) =>
      method.requiresReference;

  @override
  List<Object?> get props => [
    customerName,
    amount,
    method,
    concept,
    customerId,
    reservationId,
    courtName,
    reservationStart,
    reference,
    note,
  ];
}
