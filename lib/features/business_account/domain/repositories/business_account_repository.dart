import '../entities/business_account.dart';

abstract interface class BusinessAccountRepository {
  Future<BusinessAccount> getAccount();
}
