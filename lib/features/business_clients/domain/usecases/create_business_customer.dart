import '../../../../core/usecase/usecase.dart';
import '../entities/client_profile.dart';
import '../entities/customer_payload.dart';
import '../repositories/business_customers_repository.dart';

class CreateBusinessCustomer
    implements UseCase<ClientProfile, CustomerPayload> {
  const CreateBusinessCustomer(this._repository);

  final BusinessCustomersRepository _repository;

  @override
  Future<ClientProfile> call(CustomerPayload params) {
    return _repository.createCustomer(params);
  }
}
