import '../../../../core/usecase/usecase.dart';
import '../entities/business_account.dart';
import '../repositories/business_account_repository.dart';

class GetBusinessAccount implements UseCase<BusinessAccount, NoParams> {
  const GetBusinessAccount(this._repository);

  final BusinessAccountRepository _repository;

  @override
  Future<BusinessAccount> call(NoParams params) => _repository.getAccount();
}
