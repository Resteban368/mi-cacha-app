import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/auth_failure.dart';
import '../../../domain/entities/email_credentials.dart';
import '../../../domain/usecases/sign_in_with_credentials.dart';

part 'business_login_event.dart';
part 'business_login_state.dart';

class BusinessLoginBloc extends Bloc<BusinessLoginEvent, BusinessLoginState> {
  BusinessLoginBloc({required SignInWithCredentials signInWithCredentials})
    : _signInWithCredentials = signInWithCredentials,
      super(const BusinessLoginState()) {
    // droppable: ignora envíos repetidos mientras hay uno en curso.
    on<BusinessLoginSubmitted>(_onSubmitted, transformer: droppable());
  }

  final SignInWithCredentials _signInWithCredentials;

  Future<void> _onSubmitted(
    BusinessLoginSubmitted event,
    Emitter<BusinessLoginState> emit,
  ) async {
    emit(const BusinessLoginState(status: BusinessLoginStatus.loading));
    try {
      await _signInWithCredentials(
        EmailCredentials(email: event.email.trim(), password: event.password),
      );
      emit(const BusinessLoginState(status: BusinessLoginStatus.success));
    } on AuthException catch (error) {
      emit(
        BusinessLoginState(
          status: BusinessLoginStatus.failure,
          failure: error.failure,
        ),
      );
    } catch (_) {
      emit(
        const BusinessLoginState(
          status: BusinessLoginStatus.failure,
          failure: AuthFailure.server,
        ),
      );
    }
  }
}
