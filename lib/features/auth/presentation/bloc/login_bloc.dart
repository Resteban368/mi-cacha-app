import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_method.dart';
import '../../domain/usecases/sign_in.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required SignIn signIn})
    : _signIn = signIn,
      super(const LoginState()) {
    // droppable: ignora toques mientras hay un inicio de sesión en curso.
    on<LoginRequested>(_onRequested, transformer: droppable());
  }

  final SignIn _signIn;

  Future<void> _onRequested(
    LoginRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginState(status: LoginStatus.loading, method: event.method));
    try {
      await _signIn(event.method);
      emit(LoginState(status: LoginStatus.success, method: event.method));
    } catch (_) {
      emit(LoginState(status: LoginStatus.failure, method: event.method));
    }
  }
}
