import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/password_change.dart';
import '../../domain/usecases/change_password.dart';

enum ChangePasswordStatus { idle, submitting, success, failure }

final class ChangePasswordState extends Equatable {
  const ChangePasswordState({
    this.status = ChangePasswordStatus.idle,
    this.failure,
    this.message,
  });

  final ChangePasswordStatus status;
  final PasswordChangeFailure? failure;

  /// Mensaje de la API (400) para mostrar en el formulario.
  final String? message;

  bool get isSubmitting => status == ChangePasswordStatus.submitting;

  @override
  List<Object?> get props => [status, failure, message];
}

/// Cambio de contraseña del dueño. Un error de la API no cierra la sesión:
/// se muestra en el formulario.
class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit({required ChangePassword changePassword})
    : _changePassword = changePassword,
      super(const ChangePasswordState());

  final ChangePassword _changePassword;

  Future<void> submit(PasswordChange change) async {
    // Evita un doble envío mientras responde la API.
    if (state.isSubmitting) return;
    emit(const ChangePasswordState(status: ChangePasswordStatus.submitting));
    try {
      await _changePassword(change);
      if (isClosed) return;
      emit(const ChangePasswordState(status: ChangePasswordStatus.success));
    } on PasswordChangeException catch (error) {
      if (isClosed) return;
      emit(
        ChangePasswordState(
          status: ChangePasswordStatus.failure,
          failure: error.failure,
          message: error.message,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        const ChangePasswordState(
          status: ChangePasswordStatus.failure,
          failure: PasswordChangeFailure.server,
        ),
      );
    }
  }
}
