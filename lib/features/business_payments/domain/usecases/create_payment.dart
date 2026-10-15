import '../../../../core/usecase/usecase.dart';
import '../entities/new_payment.dart';
import '../entities/payment.dart';
import '../repositories/payments_repository.dart';

class CreatePayment implements UseCase<Payment, NewPayment> {
  const CreatePayment(this._repository);

  final PaymentsRepository _repository;

  @override
  Future<Payment> call(NewPayment payment) {
    if (payment.customerName.trim().isEmpty) {
      throw ArgumentError('El cliente es obligatorio');
    }
    if (payment.amount <= 0) {
      throw ArgumentError('El monto debe ser mayor a cero');
    }
    if (NewPayment.requiresReference(payment.method) &&
        (payment.reference?.trim().isEmpty ?? true)) {
      throw ArgumentError('La referencia es obligatoria');
    }
    return _repository.create(payment);
  }
}
