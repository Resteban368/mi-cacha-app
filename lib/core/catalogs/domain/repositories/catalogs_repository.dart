import '../entities/app_catalogs.dart';

abstract interface class CatalogsRepository {
  Future<AppCatalogs> getCatalogs();
}
