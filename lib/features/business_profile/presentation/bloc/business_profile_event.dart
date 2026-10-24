part of 'business_profile_bloc.dart';

sealed class BusinessProfileEvent extends Equatable {
  const BusinessProfileEvent();

  @override
  List<Object?> get props => [];
}

final class BusinessProfileRequested extends BusinessProfileEvent {
  const BusinessProfileRequested();
}

final class BusinessProfileSaved extends BusinessProfileEvent {
  const BusinessProfileSaved(this.draft);

  final BusinessDraft draft;

  @override
  List<Object?> get props => [draft];
}

/// Reintenta cargar el catálogo de servicios.
final class BusinessAmenitiesRequested extends BusinessProfileEvent {
  const BusinessAmenitiesRequested();
}

/// Cambios de la galería de fotos (se procesan de a uno).
sealed class BusinessPhotoEvent extends BusinessProfileEvent {
  const BusinessPhotoEvent();
}

/// Se eligió una foto: con negocio se agrega al final de la galería; sin
/// negocio queda pendiente y se sube al registrarlo.
final class BusinessPhotoPicked extends BusinessPhotoEvent {
  const BusinessPhotoPicked(this.image);

  final ImageUpload image;

  @override
  List<Object?> get props => [image];
}

/// Quita una foto de la galería; `null` descarta la foto pendiente.
final class BusinessPhotoRemoved extends BusinessPhotoEvent {
  const BusinessPhotoRemoved([this.photoId]);

  final String? photoId;

  @override
  List<Object?> get props => [photoId];
}

/// Nuevo orden de la galería (todas las fotos); la primera es la portada.
final class BusinessPhotosReordered extends BusinessPhotoEvent {
  const BusinessPhotosReordered(this.ids);

  final List<String> ids;

  @override
  List<Object?> get props => [ids];
}
