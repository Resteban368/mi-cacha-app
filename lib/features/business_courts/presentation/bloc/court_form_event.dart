part of 'court_form_bloc.dart';

sealed class CourtFormEvent extends Equatable {
  const CourtFormEvent();

  @override
  List<Object?> get props => [];
}

/// Carga el negocio, el plan y las canchas. Con [courtId] el formulario
/// edita esa cancha. [silent] actualiza sin mostrar carga.
final class CourtFormStarted extends CourtFormEvent {
  const CourtFormStarted({this.courtId, this.silent = false});

  final String? courtId;
  final bool silent;

  @override
  List<Object?> get props => [courtId, silent];
}

final class CourtFormSubmitted extends CourtFormEvent {
  const CourtFormSubmitted({
    required this.draft,
    this.uploads = const {},
    this.removals = const {},
  });

  final CourtDraft draft;

  /// Fotos nuevas o que reemplazan a la actual, por posición.
  final Map<CourtPhotoSlot, ImageUpload> uploads;

  /// Posiciones cuya foto actual se quitó (solo al editar).
  final Set<CourtPhotoSlot> removals;

  @override
  List<Object?> get props => [draft, uploads, removals];
}
