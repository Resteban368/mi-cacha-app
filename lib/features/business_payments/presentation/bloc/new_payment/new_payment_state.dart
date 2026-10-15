part of 'new_payment_bloc.dart';

enum NewPaymentStatus { initial, submitting, success, failure }

final class NewPaymentState extends Equatable {
  const NewPaymentState({this.status = NewPaymentStatus.initial, this.created});

  final NewPaymentStatus status;
  final Payment? created;

  bool get isSubmitting => status == NewPaymentStatus.submitting;

  @override
  List<Object?> get props => [status, created];
}
