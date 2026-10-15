import '../../domain/entities/new_payment.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/payments_data_source.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  const PaymentsRepositoryImpl(this._dataSource);

  final PaymentsDataSource _dataSource;

  @override
  Future<List<Payment>> getPayments() => _dataSource.getPayments();

  @override
  Future<Payment> approve(String paymentId) =>
      _dataSource.updateStatus(paymentId, PaymentStatus.approved);

  @override
  Future<Payment> reject(String paymentId, {String? reason}) => _dataSource
      .updateStatus(paymentId, PaymentStatus.rejected, rejectionReason: reason);

  @override
  Future<Payment> create(NewPayment payment) => _dataSource.create(payment);
}
