import '../../../../core/usecase/usecase.dart';
import '../entities/auth_user.dart';
import '../entities/email_credentials.dart';
import '../repositories/auth_repository.dart';

class SignInWithCredentials implements UseCase<AuthUser, EmailCredentials> {
  const SignInWithCredentials(this._repository);

  final AuthRepository _repository;

  @override
  Future<AuthUser> call(EmailCredentials credentials) =>
      _repository.signInWithCredentials(credentials);
}
