import 'package:equatable/equatable.dart';

enum CustomerFailure {
  network,
  conflict,
  notFound,
  invalid,
  server,
}

class CustomerException implements Exception, Equatable {
  const CustomerException({
    required this.failure,
    this.message,
    this.statusCode,
  });

  final CustomerFailure failure;
  final String? message;
  final int? statusCode;

  @override
  List<Object?> get props => [failure, message, statusCode];

  @override
  String toString() =>
      'CustomerException($failure, statusCode: $statusCode, message: $message)';

  @override
  bool? get stringify => true;
}
