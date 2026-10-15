import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/new_payment.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/usecases/create_payment.dart';

part 'new_payment_event.dart';
part 'new_payment_state.dart';

class NewPaymentBloc extends Bloc<NewPaymentEvent, NewPaymentState> {
  NewPaymentBloc({required CreatePayment createPayment})
    : _createPayment = createPayment,
      super(const NewPaymentState()) {
    // droppable: evita registrar dos veces el mismo pago.
    on<NewPaymentSubmitted>(_onSubmitted, transformer: droppable());
  }

  final CreatePayment _createPayment;

  Future<void> _onSubmitted(
    NewPaymentSubmitted event,
    Emitter<NewPaymentState> emit,
  ) async {
    emit(const NewPaymentState(status: NewPaymentStatus.submitting));
    try {
      final created = await _createPayment(event.payment);
      emit(NewPaymentState(status: NewPaymentStatus.success, created: created));
    } catch (_) {
      emit(const NewPaymentState(status: NewPaymentStatus.failure));
    }
  }
}
