part of 'business_profile_bloc.dart';

enum BusinessProfileStatus { initial, loading, ready, failure }

enum BusinessSaveStatus {
  idle,
  saving,

  /// Se creó el negocio (estado vacío → registrado).
  created,

  /// Se guardaron cambios de un negocio existente.
  updated,
  failure,
}

/// Carga del catálogo de servicios (`GET /catalogs`), independiente del
/// negocio: si falla, el resto del formulario sigue disponible.
enum AmenityCatalogStatus { loading, ready, failure }

/// Carga del link de reservas en línea, independiente del formulario.
enum OnlineBookingStatus { idle, loading, ready, failure }

enum BusinessPhotoStatus {
  idle,
  uploading,
  removing,
  reordering,
  uploaded,
  removed,
  reordered,

  /// La foto supera los 4 MB.
  tooLarge,

  /// La foto no es JPG ni PNG.
  invalidType,

  /// Ya hay [Business.maxPhotos] fotos.
  limitReached,
  failure;

  bool get isBusy =>
      this == uploading || this == removing || this == reordering;
}

final class BusinessProfileState extends Equatable {
  const BusinessProfileState({
    this.status = BusinessProfileStatus.initial,
    this.business,
    this.saveStatus = BusinessSaveStatus.idle,
    this.photoStatus = BusinessPhotoStatus.idle,
    this.pendingPhoto,
    this.amenityOptions = const [],
    this.amenityStatus = AmenityCatalogStatus.loading,
    this.bookingLink,
    this.bookingLinkStatus = OnlineBookingStatus.idle,
  });

  final BusinessProfileStatus status;

  /// `null` mientras el administrador no haya creado su negocio.
  final Business? business;
  final BusinessSaveStatus saveStatus;
  final BusinessPhotoStatus photoStatus;

  /// Foto elegida antes de registrar el negocio; se sube al guardarlo.
  final ImageUpload? pendingPhoto;

  /// Servicios activos del catálogo, en el orden del panel administrativo.
  final List<CatalogAmenity> amenityOptions;
  final AmenityCatalogStatus amenityStatus;

  /// Link para compartir; solo existe con el negocio registrado.
  final OnlineBookingLink? bookingLink;
  final OnlineBookingStatus bookingLinkStatus;

  bool get isSaving => saveStatus == BusinessSaveStatus.saving;

  BusinessProfileState copyWith({
    BusinessProfileStatus? status,
    Business? business,
    BusinessSaveStatus? saveStatus,
    BusinessPhotoStatus? photoStatus,
    ImageUpload? Function()? pendingPhoto,
    List<CatalogAmenity>? amenityOptions,
    AmenityCatalogStatus? amenityStatus,
    OnlineBookingLink? bookingLink,
    OnlineBookingStatus? bookingLinkStatus,
  }) => BusinessProfileState(
    status: status ?? this.status,
    business: business ?? this.business,
    saveStatus: saveStatus ?? this.saveStatus,
    photoStatus: photoStatus ?? this.photoStatus,
    pendingPhoto: pendingPhoto != null ? pendingPhoto() : this.pendingPhoto,
    amenityOptions: amenityOptions ?? this.amenityOptions,
    amenityStatus: amenityStatus ?? this.amenityStatus,
    bookingLink: bookingLink ?? this.bookingLink,
    bookingLinkStatus: bookingLinkStatus ?? this.bookingLinkStatus,
  );

  @override
  List<Object?> get props => [
    status,
    business,
    saveStatus,
    photoStatus,
    pendingPhoto,
    amenityOptions,
    amenityStatus,
    bookingLink,
    bookingLinkStatus,
  ];
}
