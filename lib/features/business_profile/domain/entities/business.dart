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
  });

  final String name;
  final String address;
  final String neighborhood;
  final String? description;

  /// Punto de llegada fijado en el mapa; `null` si no se fijó.
  final GeoPoint? location;

  /// Códigos del catálogo de servicios (`GET /catalogs`), p. ej. `WIFI`.
  final Set<String> amenities;

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
  );

  @override
  List<Object?> get props => [
    name,
    address,
    neighborhood,
    description,
    amenities,
    location,
  ];
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
    this.location,
  });

  final String id;
  final String name;
  final String address;
  final String neighborhood;
  final String? description;

  /// Códigos del catálogo de servicios (`GET /catalogs`), p. ej. `WIFI`.
  final Set<String> amenities;

  /// URL pública (HTTPS) de la foto de portada; `null` si no tiene.
  final String? imageUrl;

  /// Punto de llegada; `null` si aún no se fijó en el mapa.
  final GeoPoint? location;

  @override
  List<Object?> get props => [
    id,
    name,
    address,
    neighborhood,
    description,
    amenities,
    imageUrl,
    location,
  ];
}
