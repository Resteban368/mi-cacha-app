import 'package:equatable/equatable.dart';

/// Método de pago retornado por `GET /api/v1/catalogs`.
class CatalogPaymentMethod extends Equatable {
  const CatalogPaymentMethod({
    required this.id,
    required this.code,
    required this.name,
    required this.active,
    required this.sortOrder,
    required this.requiresReference,
  });

  final String id;

  /// Código para enviar en las peticiones (`EFECTIVO`, `NEQUI`, `BRE_B`, etc.).
  final String code;

  /// Nombre para mostrar en la interfaz (`Efectivo`, `Nequi`, `bre-b`, etc.).
  final String name;

  final bool active;
  final int sortOrder;

  /// Si es obligatorio adjuntar el número/código de referencia al registrar el pago.
  final bool requiresReference;

  factory CatalogPaymentMethod.fromJson(Map<String, dynamic> json) =>
      CatalogPaymentMethod(
        id: json['id'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        active: json['active'] as bool? ?? true,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        requiresReference: json['requiresReference'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    active,
    sortOrder,
    requiresReference,
  ];
}
