import 'package:equatable/equatable.dart';

/// Departamento de Colombia (DANE), de `GET /catalogs/departments`.
class CatalogDepartment extends Equatable {
  const CatalogDepartment({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;

  /// Código DANE, p. ej. `05`.
  final String code;
  final String name;

  factory CatalogDepartment.fromJson(Map<String, dynamic> json) =>
      CatalogDepartment(
        id: json['id'] as String,
        code: json['code'] as String? ?? '',
        name: json['name'] as String,
      );

  @override
  List<Object?> get props => [id, code, name];
}

/// Municipio de un departamento, de
/// `GET /catalogs/departments/:id/cities`.
class CatalogCity extends Equatable {
  const CatalogCity({required this.id, required this.code, required this.name});

  final String id;

  /// Código DANE, p. ej. `05001`.
  final String code;
  final String name;

  factory CatalogCity.fromJson(Map<String, dynamic> json) => CatalogCity(
    id: json['id'] as String,
    code: json['code'] as String? ?? '',
    name: json['name'] as String,
  );

  @override
  List<Object?> get props => [id, code, name];
}
