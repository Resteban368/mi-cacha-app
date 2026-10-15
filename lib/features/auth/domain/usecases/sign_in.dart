import '../../../../core/usecase/usecase.dart';
import '../entities/auth_method.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignIn implements UseCase<AuthUser, AuthMethod> {
  const SignIn(this._repository);

  final AuthRepository _repository;

  @override
  Future<AuthUser> call(AuthMethod method) => _repository.signIn(method);
}
