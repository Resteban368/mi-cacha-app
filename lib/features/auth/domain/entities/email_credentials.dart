import 'package:equatable/equatable.dart';

class EmailCredentials extends Equatable {
  const EmailCredentials({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];

  // Nunca exponer la contraseña en logs.
  @override
  String toString() => 'EmailCredentials($email, ***)';
}
