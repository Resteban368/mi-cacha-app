import '../../domain/entities/business_account.dart';
import '../../domain/entities/password_change.dart';
import '../../domain/repositories/business_account_repository.dart';
import '../datasources/business_account_data_source.dart';

class BusinessAccountRepositoryImpl implements BusinessAccountRepository {
  const BusinessAccountRepositoryImpl(this._dataSource);

  final BusinessAccountDataSource _dataSource;

  @override
  Future<BusinessAccount> getAccount() => _dataSource.getAccount();

  @override
  Future<void> changePassword(PasswordChange change) =>
      _dataSource.changePassword(change);
}
