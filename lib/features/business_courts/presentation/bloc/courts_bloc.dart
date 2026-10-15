import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/court.dart';
import '../../domain/usecases/get_courts.dart';

part 'courts_event.dart';
part 'courts_state.dart';

/// Lista de canchas del negocio.
class CourtsBloc extends Bloc<CourtsEvent, CourtsState> {
  CourtsBloc({required GetCourts getCourts})
    : _getCourts = getCourts,
      super(const CourtsState()) {
    on<CourtsRequested>(_onRequested, transformer: restartable());
  }

  final GetCourts _getCourts;

  Future<void> _onRequested(
    CourtsRequested event,
    Emitter<CourtsState> emit,
  ) async {
    // Al refrescar se mantiene la lista visible mientras carga.
    if (!event.refresh) emit(state.copyWith(status: CourtsStatus.loading));
    try {
      final courts = await _getCourts(const NoParams());
      emit(CourtsState(status: CourtsStatus.ready, courts: courts));
    } catch (_) {
      emit(state.copyWith(status: CourtsStatus.failure));
    } finally {
      event.done?.complete();
    }
  }
}
