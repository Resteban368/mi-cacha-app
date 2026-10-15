import '../../../../core/usecase/usecase.dart';
import '../entities/payment.dart';
import '../repositories/payments_repository.dart';

class GetPayments implements UseCase<List<Payment>, NoParams> {
  const GetPayments(this._repository);

  final PaymentsRepository _repository;

  @override
  Future<List<Payment>> call(NoParams params) => _repository.getPayments();
}
