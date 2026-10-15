import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/payment.dart';
import '../repositories/payments_repository.dart';

class ValidatePaymentParams extends Equatable {
  const ValidatePaymentParams.approve(this.paymentId)
    : approved = true,
      reason = null;

  const ValidatePaymentParams.reject(this.paymentId, {this.reason})
    : approved = false;

  final String paymentId;
  final bool approved;
  final String? reason;

  @override
  List<Object?> get props => [paymentId, approved, reason];
}

/// Aprueba o rechaza un pago pendiente de validación.
class ValidatePayment implements UseCase<Payment, ValidatePaymentParams> {
  const ValidatePayment(this._repository);

  final PaymentsRepository _repository;

  @override
  Future<Payment> call(ValidatePaymentParams params) {
    if (params.approved) return _repository.approve(params.paymentId);
    final reason = params.reason?.trim();
    return _repository.reject(
      params.paymentId,
      reason: reason == null || reason.isEmpty ? null : reason,
    );
  }
}
