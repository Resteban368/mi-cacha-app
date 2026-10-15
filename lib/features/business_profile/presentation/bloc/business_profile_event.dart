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

/// Cambios de la foto de portada (se procesan de a uno).
sealed class BusinessCoverEvent extends BusinessProfileEvent {
  const BusinessCoverEvent();
}

/// Se eligió una foto: con negocio se sube al instante; sin negocio queda
/// pendiente y se sube al registrarlo.
final class BusinessCoverPicked extends BusinessCoverEvent {
  const BusinessCoverPicked(this.image);

  final ImageUpload image;

  @override
  List<Object?> get props => [image];
}

final class BusinessCoverRemoved extends BusinessCoverEvent {
  const BusinessCoverRemoved();
}
