import '../entities/app_catalogs.dart';
import '../entities/catalog_geography.dart';

abstract interface class CatalogsRepository {
  Future<AppCatalogs> getCatalogs();

  /// Los 33 departamentos de Colombia.
  Future<List<CatalogDepartment>> getDepartments();

  /// Municipios del departamento, ya ordenados por nombre.
  Future<List<CatalogCity>> getCities(String departmentId);
}
