import '../../../../core/usecase/usecase.dart';
import '../entities/password_change.dart';
import '../repositories/business_account_repository.dart';

class ChangePassword implements UseCase<void, PasswordChange> {
  const ChangePassword(this._repository);

  final BusinessAccountRepository _repository;

  /// Lanza [PasswordChangeException] si la API lo rechaza.
  @override
  Future<void> call(PasswordChange change) =>
      _repository.changePassword(change);
}
