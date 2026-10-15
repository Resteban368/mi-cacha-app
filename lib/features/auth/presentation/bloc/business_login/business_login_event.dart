part of 'business_login_bloc.dart';

sealed class BusinessLoginEvent extends Equatable {
  const BusinessLoginEvent();

  @override
  List<Object?> get props => [];
}

final class BusinessLoginSubmitted extends BusinessLoginEvent {
  const BusinessLoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
