import '../../domain/entities/app_catalogs.dart';
import '../../domain/entities/catalog_geography.dart';

abstract interface class CatalogsDataSource {
  Future<AppCatalogs> getCatalogs();

  Future<List<CatalogDepartment>> getDepartments();

  Future<List<CatalogCity>> getCities(String departmentId);
}
