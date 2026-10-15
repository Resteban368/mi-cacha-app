part of 'business_login_bloc.dart';

enum BusinessLoginStatus { initial, loading, success, failure }

final class BusinessLoginState extends Equatable {
  const BusinessLoginState({
    this.status = BusinessLoginStatus.initial,
    this.failure,
  });

  final BusinessLoginStatus status;

  /// Motivo del error cuando [status] es `failure`.
  final AuthFailure? failure;

  bool get isLoading => status == BusinessLoginStatus.loading;

  @override
  List<Object?> get props => [status, failure];
}
