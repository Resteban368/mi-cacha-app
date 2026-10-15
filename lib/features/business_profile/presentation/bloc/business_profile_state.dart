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

enum BusinessCoverStatus {
  idle,
  uploading,
  removing,
  uploaded,
  removed,

  /// La foto supera los 4 MB.
  tooLarge,

  /// La foto no es JPG ni PNG.
  invalidType,
  failure;

  bool get isBusy => this == uploading || this == removing;
}

final class BusinessProfileState extends Equatable {
  const BusinessProfileState({
    this.status = BusinessProfileStatus.initial,
    this.business,
    this.saveStatus = BusinessSaveStatus.idle,
    this.coverStatus = BusinessCoverStatus.idle,
    this.pendingCover,
    this.amenityOptions = const [],
    this.amenityStatus = AmenityCatalogStatus.loading,
  });

  final BusinessProfileStatus status;

  /// `null` mientras el administrador no haya creado su negocio.
  final Business? business;
  final BusinessSaveStatus saveStatus;
  final BusinessCoverStatus coverStatus;

  /// Foto elegida antes de registrar el negocio; se sube al guardarlo.
  final ImageUpload? pendingCover;

  /// Servicios activos del catálogo, en el orden del panel administrativo.
  final List<CatalogAmenity> amenityOptions;
  final AmenityCatalogStatus amenityStatus;

  bool get isSaving => saveStatus == BusinessSaveStatus.saving;

  BusinessProfileState copyWith({
    BusinessProfileStatus? status,
    Business? business,
    BusinessSaveStatus? saveStatus,
    BusinessCoverStatus? coverStatus,
    ImageUpload? Function()? pendingCover,
    List<CatalogAmenity>? amenityOptions,
    AmenityCatalogStatus? amenityStatus,
  }) => BusinessProfileState(
    status: status ?? this.status,
    business: business ?? this.business,
    saveStatus: saveStatus ?? this.saveStatus,
    coverStatus: coverStatus ?? this.coverStatus,
    pendingCover: pendingCover != null ? pendingCover() : this.pendingCover,
    amenityOptions: amenityOptions ?? this.amenityOptions,
    amenityStatus: amenityStatus ?? this.amenityStatus,
  );

  @override
  List<Object?> get props => [
    status,
    business,
    saveStatus,
    coverStatus,
    pendingCover,
    amenityOptions,
    amenityStatus,
  ];
}
