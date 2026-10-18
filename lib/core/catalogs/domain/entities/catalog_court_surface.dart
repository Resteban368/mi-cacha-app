import 'package:equatable/equatable.dart';

import '../../../domain/entities/sport.dart';

/// Superficie o tipo de grama retornada por `GET /api/v1/catalogs`.
class CatalogCourtSurface extends Equatable {
  const CatalogCourtSurface({
    required this.code,
    required this.name,
    this.sports = const {},
    this.sortOrder = 0,
  });

  /// Código para enviar en las peticiones (`GRAMA_SINTETICA`, `MADERA`, etc.).
  final String code;

  /// Nombre para mostrar en la interfaz (`Grama sintética`, `Madera`, etc.).
  final String name;

  /// Deportes en los que se ofrece; vacío = todos.
  final Set<Sport> sports;
  final int sortOrder;

  bool appliesTo(Sport sport) => sports.isEmpty || sports.contains(sport);

  factory CatalogCourtSurface.fromJson(Map<String, dynamic> json) =>
      CatalogCourtSurface(
        code: json['code'] as String,
        name: json['name'] as String,
        sports: {
          for (final code in (json['sports'] as List<dynamic>? ?? const []))
            ?Sport.fromApi('$code'),
        },
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [code, name, sports, sortOrder];
}
