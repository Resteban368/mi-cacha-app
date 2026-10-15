import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/reservation.dart';
import '../../../domain/entities/reservation_failure.dart';
import '../../../domain/usecases/booking_usecases.dart';

enum ReservationDetailLoad { loading, ready, failure }

enum ReservationAction { idle, working, done, failure }

final class ReservationDetailState extends Equatable {
  const ReservationDetailState({
    this.load = ReservationDetailLoad.loading,
    this.reservation,
    this.action = ReservationAction.idle,
    this.failure,
    this.failureMessage,
    this.changed = false,
  });

  final ReservationDetailLoad load;
  final Reservation? reservation;
  final ReservationAction action;
  final ReservationFailure? failure;
  final String? failureMessage;

  /// Si se canceló o cambió el estado (la agenda debe recargarse).
  final bool changed;

  ReservationDetailState copyWith({
    ReservationDetailLoad? load,
    Reservation? reservation,
    ReservationAction? action,
    ReservationFailure? Function()? failure,
    String? Function()? failureMessage,
    bool? changed,
  }) => ReservationDetailState(
    load: load ?? this.load,
    reservation: reservation ?? this.reservation,
    action: action ?? this.action,
    failure: failure != null ? failure() : this.failure,
    failureMessage: failureMessage != null
        ? failureMessage()
        : this.failureMessage,
    changed: changed ?? this.changed,
  );

  @override
  List<Object?> get props => [
    load,
    reservation,
    action,
    failure,
    failureMessage,
    changed,
  ];
}

/// Detalle de una reserva con sus acciones: cancelar (con motivo) y marcar
/// jugada, no asistió o de nuevo confirmada.
class ReservationDetailCubit extends Cubit<ReservationDetailState> {
  ReservationDetailCubit({
    required GetReservation getReservation,
    required CancelReservation cancelReservation,
    required UpdateReservationStatus updateStatus,
  }) : _getReservation = getReservation,
       _cancel = cancelReservation,
       _updateStatus = updateStatus,
       super(const ReservationDetailState());

  final GetReservation _getReservation;
  final CancelReservation _cancel;
  final UpdateReservationStatus _updateStatus;

  /// Muestra [initial] (de la agenda) mientras trae el detalle completo
  /// (pagos, cliente).
  Future<void> load(Reservation initial) async {
    emit(
      state.copyWith(load: ReservationDetailLoad.ready, reservation: initial),
    );
    try {
      final reservation = await _getReservation(initial.id);
      if (isClosed) return;
      emit(state.copyWith(reservation: reservation));
    } catch (_) {
      // Se queda con los datos de la agenda.
    }
  }

  Future<void> cancel(String reason) =>
      _run(() => _cancel((id: state.reservation!.id, reason: reason)));

  Future<void> setStatus(ReservationStatus status) =>
      _run(() => _updateStatus((id: state.reservation!.id, status: status)));

  Future<void> _run(Future<Reservation> Function() request) async {
    if (state.action == ReservationAction.working) return;
    emit(
      state.copyWith(
        action: ReservationAction.working,
        failure: () => null,
        failureMessage: () => null,
      ),
    );
    try {
      final reservation = await request();
      if (isClosed) return;
      emit(
        state.copyWith(
          reservation: reservation,
          action: ReservationAction.done,
          changed: true,
        ),
      );
    } on ReservationException catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          action: ReservationAction.failure,
          failure: () => error.failure,
          failureMessage: () => error.message,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          action: ReservationAction.failure,
          failure: () => ReservationFailure.server,
        ),
      );
    }
  }
}
