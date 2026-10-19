import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/sport.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../business_courts/domain/entities/court.dart';
import '../../../business_courts/domain/usecases/get_courts.dart';
import '../../domain/entities/business_dashboard.dart';
import '../../domain/entities/dashboard_failure.dart';
import '../../domain/usecases/get_business_dashboard.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

/// Dashboard analítico: métricas del período con filtros por deporte y
/// cancha. Gana el último filtro elegido.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required GetBusinessDashboard getDashboard,
    required GetCourts getCourts,
  }) : _getDashboard = getDashboard,
       _getCourts = getCourts,
       super(const DashboardState()) {
    on<DashboardEvent>(_onLoad, transformer: restartable());
  }

  final GetBusinessDashboard _getDashboard;
  final GetCourts _getCourts;

  Future<void> _onLoad(
    DashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    var filter = switch (event) {
      DashboardFilterChanged(:final filter) => filter,
      _ => state.filter,
    };
    // Una cancha de otro deporte no aplica con el nuevo deporte.
    if (filter.courtId != null &&
        filter.sport != null &&
        state.courts.any(
          (c) => c.id == filter.courtId && c.sport != filter.sport,
        )) {
      filter = filter.copyWith(courtId: () => null);
    }
    emit(
      state.copyWith(
        status: DashboardStatus.loading,
        filter: filter,
        failure: () => null,
        failureMessage: () => null,
      ),
    );

    if (event is DashboardStarted && state.courts.isEmpty) {
      try {
        final courts = await _getCourts(const NoParams());
        emit(state.copyWith(courts: courts));
      } catch (_) {
        // Sin canchas no se ofrecen esos filtros; el resto funciona.
      }
    }

    try {
      final dashboard = await _getDashboard(filter);
      emit(
        state.copyWith(
          status: DashboardStatus.success,
          dashboard: () => dashboard,
        ),
      );
    } on DashboardException catch (error) {
      emit(
        state.copyWith(
          status: DashboardStatus.failure,
          failure: () => error.failure,
          failureMessage: () => error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: DashboardStatus.failure,
          failure: () => DashboardFailure.server,
        ),
      );
    }
  }
}
