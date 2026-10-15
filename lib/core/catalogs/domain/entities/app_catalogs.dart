import 'package:equatable/equatable.dart';

import 'catalog_amenity.dart';
import 'catalog_payment_method.dart';

/// Catálogos de la plataforma retornados por `GET /api/v1/catalogs`.
class AppCatalogs extends Equatable {
  const AppCatalogs({required this.amenities, required this.paymentMethods});

  final List<CatalogAmenity> amenities;
  final List<CatalogPaymentMethod> paymentMethods;

  factory AppCatalogs.fromJson(Map<String, dynamic> json) => AppCatalogs(
    amenities: [
      for (final item in (json['amenities'] as List<dynamic>? ?? const []))
        CatalogAmenity.fromJson(item as Map<String, dynamic>),
    ],
    paymentMethods: [
      for (final item in (json['paymentMethods'] as List<dynamic>? ?? const []))
        CatalogPaymentMethod.fromJson(item as Map<String, dynamic>),
    ],
  );

  @override
  List<Object?> get props => [amenities, paymentMethods];
}
