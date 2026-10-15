import '../../domain/entities/app_catalogs.dart';

abstract interface class CatalogsDataSource {
  Future<AppCatalogs> getCatalogs();
}
