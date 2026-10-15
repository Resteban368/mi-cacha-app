import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecase/usecase.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/usecases/get_payments.dart';
import '../../../domain/usecases/validate_payment.dart';

part 'payments_event.dart';
part 'payments_state.dart';

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  PaymentsBloc({
    required GetPayments getPayments,
    required ValidatePayment validatePayment,
  }) : _getPayments = getPayments,
       _validatePayment = validatePayment,
       super(const PaymentsState()) {
    on<PaymentsRequested>(_onRequested, transformer: restartable());
    on<PaymentsTabChanged>(_onTabChanged);
    // Validaciones en paralelo (una por pago); cada una marca su id.
    on<PaymentApproved>(_onApproved);
    on<PaymentRejected>(_onRejected);
  }

  final GetPayments _getPayments;
  final ValidatePayment _validatePayment;
  int _noticeId = 0;

  Future<void> _onRequested(
    PaymentsRequested event,
    Emitter<PaymentsState> emit,
  ) async {
    // Si ya hay datos, se recarga sin ocultar el listado.
    if (state.payments.isEmpty) {
      emit(state.copyWith(status: PaymentsStatus.loading));
    }
    try {
      final payments = await _getPayments(const NoParams());
      emit(state.copyWith(status: PaymentsStatus.success, payments: payments));
    } catch (_) {
      emit(
        state.payments.isEmpty
            ? state.copyWith(status: PaymentsStatus.failure)
            : state.copyWith(
                notice: PaymentsNotice(
                  ++_noticeId,
                  'No pudimos actualizar los pagos.',
                  isError: true,
                ),
              ),
      );
    }
  }

  void _onTabChanged(PaymentsTabChanged event, Emitter<PaymentsState> emit) =>
      emit(state.copyWith(tab: event.tab));

  Future<void> _onApproved(
    PaymentApproved event,
    Emitter<PaymentsState> emit,
  ) => _validate(
    emit,
    event.paymentId,
    ValidatePaymentParams.approve(event.paymentId),
    (p) => 'Pago de ${AppFormatters.cop(p.amount)} aprobado',
  );

  Future<void> _onRejected(
    PaymentRejected event,
    Emitter<PaymentsState> emit,
  ) => _validate(
    emit,
    event.paymentId,
    ValidatePaymentParams.reject(event.paymentId, reason: event.reason),
    (p) => 'Pago de ${p.customerName} rechazado',
  );

  Future<void> _validate(
    Emitter<PaymentsState> emit,
    String id,
    ValidatePaymentParams params,
    String Function(Payment) successMessage,
  ) async {
    if (state.processing.contains(id)) return;
    emit(state.copyWith(processing: {...state.processing, id}));
    try {
      final updated = await _validatePayment(params);
      emit(
        state.copyWith(
          payments: [for (final p in state.payments) p.id == id ? updated : p],
          processing: {...state.processing}..remove(id),
          notice: PaymentsNotice(++_noticeId, successMessage(updated)),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          processing: {...state.processing}..remove(id),
          notice: PaymentsNotice(
            ++_noticeId,
            'No pudimos validar el pago. Intenta de nuevo.',
            isError: true,
          ),
        ),
      );
    }
  }
}
