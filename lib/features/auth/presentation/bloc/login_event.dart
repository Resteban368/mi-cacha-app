part of 'login_bloc.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

final class LoginRequested extends LoginEvent {
  const LoginRequested(this.method);

  final AuthMethod method;

  @override
  List<Object?> get props => [method];
}
