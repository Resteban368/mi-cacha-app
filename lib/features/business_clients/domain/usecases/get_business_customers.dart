import '../../../../core/usecase/usecase.dart';
import '../entities/customer_query.dart';
import '../entities/customers_page_result.dart';
import '../repositories/business_customers_repository.dart';

class GetBusinessCustomers
    implements UseCase<CustomersPageResult, CustomerQuery> {
  const GetBusinessCustomers(this._repository);

  final BusinessCustomersRepository _repository;

  @override
  Future<CustomersPageResult> call(CustomerQuery params) {
    return _repository.getCustomers(params);
  }
}
