part of 'courts_bloc.dart';

sealed class CourtsEvent extends Equatable {
  const CourtsEvent();

  @override
  List<Object?> get props => [];
}

final class CourtsRequested extends CourtsEvent {
  const CourtsRequested({this.refresh = false, this.done});

  /// Deslizar para actualizar: no reemplaza la lista por la carga.
  final bool refresh;

  /// Se completa al terminar (aunque no cambie nada), para cerrar el
  /// indicador de "deslizar para actualizar".
  final Completer<void>? done;

  @override
  List<Object?> get props => [refresh];
}
