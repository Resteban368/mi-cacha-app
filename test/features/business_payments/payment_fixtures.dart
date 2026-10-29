import 'package:mi_cancha/features/business_payments/domain/entities/payment.dart';

final now = DateTime(2026, 10, 9, 19, 15);

Payment payment({
  required String id,
  PaymentStatus status = PaymentStatus.pending,
  int amount = 60000,
  PaymentMethod method = PaymentMethod.nequi,
  String customer = 'Valentina Dussán',
  int minutesAgo = 5,
  String? reason,
  int? productsAmount,
  bool walkIn = false,
}) => Payment(
  id: id,
  customerName: customer,
  amount: amount,
  method: method,
  concept: walkIn ? PaymentConcept.venta : PaymentConcept.saldo,
  reference: method == PaymentMethod.efectivo ? null : 'M$id',
  courtName: walkIn ? null : 'Cancha Múltiple',
  reservationStart: walkIn ? null : DateTime(2026, 10, 9, 19),
  productsAmount: walkIn ? amount : productsAmount ?? 0,
  receivedAt: now.subtract(Duration(minutes: minutesAgo)),
  status: status,
  rejectionReason: reason,
);

final samplePayments = [
  payment(id: 'a'),
  payment(id: 'b', amount: 50000, customer: 'Torneo Nocturno'),
  payment(id: 'c', status: PaymentStatus.approved, amount: 100000),
  payment(
    id: 'd',
    status: PaymentStatus.rejected,
    amount: 30000,
    reason: 'No coincide',
  ),
];
