import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/start_destination.dart';
import '../../domain/usecases/get_app_version.dart';
import '../../domain/usecases/resolve_start_destination.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc({
    required ResolveStartDestination resolveStartDestination,
    required GetAppVersion getAppVersion,
    this.minDisplayDuration = const Duration(milliseconds: 1800),
  }) : _resolveStartDestination = resolveStartDestination,
       _getAppVersion = getAppVersion,
       super(const SplashState()) {
    on<SplashStarted>(_onStarted);
  }

  final ResolveStartDestination _resolveStartDestination;
  final GetAppVersion _getAppVersion;

  /// Tiempo mínimo visible para que la marca no "parpadee" en arranques rápidos.
  final Duration minDisplayDuration;

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    final minDelay = Future<void>.delayed(minDisplayDuration);
    final destinationFuture = _resolveStartDestination(const NoParams());

    final version = await _getAppVersion(const NoParams());
    emit(state.copyWith(version: version));

    final destination = await destinationFuture;
    await minDelay;
    emit(state.copyWith(destination: destination));
  }
}
