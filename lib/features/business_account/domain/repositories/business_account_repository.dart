import '../entities/business_account.dart';
import '../entities/password_change.dart';

abstract interface class BusinessAccountRepository {
  Future<BusinessAccount> getAccount();

  /// Lanza [PasswordChangeException] si la API lo rechaza.
  Future<void> changePassword(PasswordChange change);
}
