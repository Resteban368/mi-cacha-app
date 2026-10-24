import 'package:equatable/equatable.dart';

/// Cambio de contraseña del dueño del negocio (`PUT /auth/password`).
class PasswordChange extends Equatable {
  const PasswordChange({
    required this.currentPassword,
    required this.newPassword,
  });

  /// Largo que acepta la API, igual que en el registro.
  static const minLength = 8;
  static const maxLength = 72;

  final String currentPassword;
  final String newPassword;

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

enum PasswordChangeFailure {
  /// 400 de la API: actual incorrecta, nueva igual a la actual o formato
  /// inválido. Trae el mensaje para mostrarlo en el formulario.
  rejected,
  network,
  server,
}

class PasswordChangeException implements Exception {
  const PasswordChangeException(this.failure, {this.message});

  final PasswordChangeFailure failure;
  final String? message;

  @override
  String toString() => 'PasswordChangeException($failure, $message)';
}
