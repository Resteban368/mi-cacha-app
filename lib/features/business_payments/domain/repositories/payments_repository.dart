import '../entities/new_payment.dart';
import '../entities/payment.dart';

abstract interface class PaymentsRepository {
  /// Pagos del negocio, más recientes primero.
  Future<List<Payment>> getPayments();

  Future<Payment> approve(String paymentId);

  Future<Payment> reject(String paymentId, {String? reason});

  /// Registra un pago hecho en el negocio (queda aprobado).
  Future<Payment> create(NewPayment payment);
}
