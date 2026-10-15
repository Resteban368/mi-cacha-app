import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/clock.dart';
import '../../domain/entities/day_agenda.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/reservation_filter.dart';
import '../../domain/usecases/get_day_reservations.dart';

part 'business_reservations_event.dart';
part 'business_reservations_state.dart';

class BusinessReservationsBloc
    extends Bloc<BusinessReservationsEvent, BusinessReservationsState> {
  BusinessReservationsBloc({
    required GetDayReservations getDayReservations,
    required Clock clock,
    Duration? tickInterval = const Duration(minutes: 1),
  }) : _getDayReservations = getDayReservations,
       _clock = clock,
       super(
         BusinessReservationsState(
           day: _dateOnly(clock.now()),
           now: clock.now(),
         ),
       ) {
    // restartable: si cambia el día mientras carga, gana la última petición.
    on<ReservationsRequested>(_onRequested, transformer: restartable());
    on<ReservationsRefreshed>(_onRefreshed, transformer: droppable());
    on<ReservationsFilterToggled>(_onFilterToggled);
    on<ReservationsClockTicked>(_onClockTicked);

    if (tickInterval != null) {
      _ticker = Timer.periodic(
        tickInterval,
        (_) => add(const ReservationsClockTicked()),
      );
    }
  }

  final GetDayReservations _getDayReservations;
  final Clock _clock;
  Timer? _ticker;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _onRequested(
    ReservationsRequested event,
    Emitter<BusinessReservationsState> emit,
  ) async {
    final day = _dateOnly(event.day ?? _clock.now());
    emit(
      state.copyWith(
        status: ReservationsStatus.loading,
        day: day,
        now: _clock.now(),
        reservations: const [],
        filter: () => null,
      ),
    );
    try {
      final reservations = await _getDayReservations(day);
      emit(
        state.copyWith(
          status: ReservationsStatus.success,
          reservations: reservations,
          now: _clock.now(),
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: ReservationsStatus.failure));
    }
  }

  Future<void> _onRefreshed(
    ReservationsRefreshed event,
    Emitter<BusinessReservationsState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final reservations = await _getDayReservations(state.day);
      emit(
        state.copyWith(
          status: ReservationsStatus.success,
          reservations: reservations,
          now: _clock.now(),
          isRefreshing: false,
        ),
      );
    } catch (_) {
      // Se conserva el listado anterior; solo se informa el fallo.
      emit(
        state.copyWith(
          status: state.reservations.isEmpty
              ? ReservationsStatus.failure
              : state.status,
          isRefreshing: false,
        ),
      );
    }
  }

  void _onFilterToggled(
    ReservationsFilterToggled event,
    Emitter<BusinessReservationsState> emit,
  ) {
    emit(
      state.copyWith(
        filter: () => state.filter == event.filter ? null : event.filter,
      ),
    );
  }

  void _onClockTicked(
    ReservationsClockTicked event,
    Emitter<BusinessReservationsState> emit,
  ) {
    emit(state.copyWith(now: _clock.now()));
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
