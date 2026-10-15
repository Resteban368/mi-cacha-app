import '../../domain/entities/app_catalogs.dart';
import '../../domain/repositories/catalogs_repository.dart';
import '../datasources/catalogs_data_source.dart';

class CatalogsRepositoryImpl implements CatalogsRepository {
  const CatalogsRepositoryImpl(this._dataSource);

  final CatalogsDataSource _dataSource;

  @override
  Future<AppCatalogs> getCatalogs() => _dataSource.getCatalogs();
}
