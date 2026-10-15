import 'package:equatable/equatable.dart';

/// Servicio o instalación retornado por `GET /api/v1/catalogs`.
class CatalogAmenity extends Equatable {
  const CatalogAmenity({
    required this.id,
    required this.code,
    required this.name,
    required this.active,
    required this.sortOrder,
  });

  final String id;

  /// Código para enviar en las peticiones (`PARQUEADERO`, `WIFI`, etc.).
  final String code;

  /// Nombre para mostrar en la interfaz (`Parqueadero`, `WiFi Gratis`, etc.).
  final String name;

  final bool active;
  final int sortOrder;

  factory CatalogAmenity.fromJson(Map<String, dynamic> json) => CatalogAmenity(
    id: json['id'] as String,
    code: json['code'] as String,
    name: json['name'] as String,
    active: json['active'] as bool? ?? true,
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  );

  @override
  List<Object?> get props => [id, code, name, active, sortOrder];
}
