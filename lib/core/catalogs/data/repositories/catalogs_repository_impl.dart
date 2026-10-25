import '../../domain/entities/app_catalogs.dart';
import '../../domain/entities/catalog_geography.dart';
import '../../domain/repositories/catalogs_repository.dart';
import '../datasources/catalogs_data_source.dart';

class CatalogsRepositoryImpl implements CatalogsRepository {
  CatalogsRepositoryImpl(this._dataSource);

  final CatalogsDataSource _dataSource;

  // Departamentos y municipios (DANE) no cambian: se guardan en memoria
  // durante la sesión. Un error no se guarda, así se puede reintentar.
  Future<List<CatalogDepartment>>? _departments;
  final _cities = <String, Future<List<CatalogCity>>>{};

  @override
  Future<AppCatalogs> getCatalogs() => _dataSource.getCatalogs();

  @override
  Future<List<CatalogDepartment>> getDepartments() =>
      _departments ??= _remember(
        _dataSource.getDepartments(),
        onError: () => _departments = null,
      );

  @override
  Future<List<CatalogCity>> getCities(String departmentId) =>
      _cities[departmentId] ??= _remember(
        _dataSource.getCities(departmentId),
        onError: () => _cities.remove(departmentId),
      );

  static Future<List<T>> _remember<T>(
    Future<List<T>> request, {
    required void Function() onError,
  }) async {
    try {
      return List.unmodifiable(await request);
    } catch (_) {
      onError();
      rethrow;
    }
  }
}
