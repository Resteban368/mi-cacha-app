part of 'login_bloc.dart';

enum LoginStatus { initial, loading, success, failure }

final class LoginState extends Equatable {
  const LoginState({this.status = LoginStatus.initial, this.method});

  final LoginStatus status;

  /// Método en curso o último usado; permite mostrar el loader en su botón.
  final AuthMethod? method;

  bool get isLoading => status == LoginStatus.loading;

  @override
  List<Object?> get props => [status, method];
}
