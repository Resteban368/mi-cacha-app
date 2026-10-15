import 'package:mi_cancha/features/business_profile/domain/entities/business.dart';
import 'package:mi_cancha/core/catalogs/domain/entities/app_catalogs.dart';
import 'package:mi_cancha/core/catalogs/domain/entities/catalog_amenity.dart';

const draft = BusinessDraft(
  name: 'Complejo Deportivo El Campín',
  address: 'Carrera 11 # 18-45',
  neighborhood: 'Centro',
  description: 'Canchas sintéticas techadas',
  amenities: {'PARQUEADERO', 'WIFI'},
);

const business = Business(
  id: 'b1',
  name: 'Complejo Deportivo El Campín',
  address: 'Carrera 11 # 18-45',
  neighborhood: 'Centro',
  description: 'Canchas sintéticas techadas',
  amenities: {'PARQUEADERO', 'WIFI'},
);

/// Servicios activos del catálogo (`GET /catalogs`), en el orden del panel.
const amenityCatalog = [
  CatalogAmenity(
    id: 'a1',
    code: 'PARQUEADERO',
    name: 'Parqueadero',
    active: true,
    sortOrder: 1,
  ),
  CatalogAmenity(
    id: 'a2',
    code: 'WIFI',
    name: 'WiFi Gratis',
    active: true,
    sortOrder: 2,
  ),
  CatalogAmenity(
    id: 'a3',
    code: 'SAUNA',
    name: 'Sauna',
    active: true,
    sortOrder: 3,
  ),
];

const catalogs = AppCatalogs(amenities: amenityCatalog, paymentMethods: []);
