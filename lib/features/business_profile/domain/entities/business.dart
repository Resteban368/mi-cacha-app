import 'package:equatable/equatable.dart';

import '../../../../core/location/geo_point.dart';

/// Datos de la sede deportiva que se capturan al crear o editar el negocio.
class BusinessDraft extends Equatable {
  const BusinessDraft({
    required this.name,
    required this.address,
    required this.neighborhood,
    this.description,
    this.amenities = const {},
    this.location,
    this.cityId,
  });

  final String name;
  final String address;
  final String neighborhood;
  final String? description;

  /// Punto de llegada fijado en el mapa; `null` si no se fijó.
  final GeoPoint? location;

  /// Códigos del catálogo de servicios (`GET /catalogs`), p. ej. `WIFI`.
  final Set<String> amenities;

  /// Municipio elegido (no el departamento). Obligatorio al crear; al
  /// editar, `null` conserva la ciudad actual.
  final String? cityId;

  /// Nombre, dirección y barrio son obligatorios (mínimos de la API).
  bool get isComplete =>
      name.trim().length >= 2 &&
      address.trim().length >= 3 &&
      neighborhood.trim().length >= 2;

  BusinessDraft copyWith({Set<String>? amenities}) => BusinessDraft(
    name: name,
    address: address,
    neighborhood: neighborhood,
    description: description,
    amenities: amenities ?? this.amenities,
    location: location,
    cityId: cityId,
  );

  @override
  List<Object?> get props => [
    name,
    address,
    neighborhood,
    description,
    amenities,
    location,
    cityId,
  ];
}

/// Ciudad del negocio con su departamento.
class City extends Equatable {
  const City({
    required this.id,
    required this.name,
    required this.departmentId,
    required this.departmentName,
  });

  final String id;
  final String name;
  final String departmentId;
  final String departmentName;

  /// «Medellín, Antioquia».
  String get label => '$name, $departmentName';

  @override
  List<Object?> get props => [id, name, departmentId, departmentName];
}

/// Foto de la galería del negocio.
class BusinessPhoto extends Equatable {
  const BusinessPhoto({required this.id, required this.url});

  final String id;

  /// URL pública (HTTPS).
  final String url;

  @override
  List<Object?> get props => [id, url];
}

/// Datos que el negocio debe tener completos antes de usar el panel.
enum BusinessRequirement {
  basics('nombre, dirección y barrio'),
  city('ciudad'),
  location('ubicación en el mapa'),
  photo('al menos una foto');

  const BusinessRequirement(this.label);

  final String label;
}

/// Negocio (sede deportiva) registrado por el administrador.
class Business extends Equatable {
  const Business({
    required this.id,
    required this.name,
    required this.address,
    required this.neighborhood,
    this.description,
    this.amenities = const {},
    this.imageUrl,
    this.photos = const [],
    this.location,
    this.city,
  });

  /// Límite de fotos de la galería que acepta la API.
  static const maxPhotos = 5;

  final String id;
  final String name;
  final String address;
  final String neighborhood;
  final String? description;

  /// Códigos del catálogo de servicios (`GET /catalogs`), p. ej. `WIFI`.
  final Set<String> amenities;

  /// URL pública (HTTPS) de la foto de portada; `null` si no tiene.
  final String? imageUrl;

  /// Galería en orden; la primera es la portada del directorio web.
  final List<BusinessPhoto> photos;

  bool get canAddPhoto => photos.length < maxPhotos;

  /// Lo que falta para dar por completo el negocio; vacío si está listo.
  List<BusinessRequirement> get missingRequirements => [
    if (name.trim().length < 2 ||
        address.trim().length < 3 ||
        neighborhood.trim().length < 2)
      BusinessRequirement.basics,
    if (city == null) BusinessRequirement.city,
    if (location == null) BusinessRequirement.location,
    if (photos.isEmpty && imageUrl == null) BusinessRequirement.photo,
  ];

  /// Punto de llegada; `null` si aún no se fijó en el mapa.
  final GeoPoint? location;

  /// `null` en negocios anteriores que aún no la completaron.
  final City? city;

  @override
  List<Object?> get props => [
    id,
    name,
    address,
    neighborhood,
    description,
    amenities,
    imageUrl,
    photos,
    location,
    city,
  ];
}
