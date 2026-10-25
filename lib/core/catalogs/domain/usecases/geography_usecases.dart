import '../../../usecase/usecase.dart';
import '../entities/catalog_geography.dart';
import '../repositories/catalogs_repository.dart';

class GetDepartments implements UseCase<List<CatalogDepartment>, NoParams> {
  const GetDepartments(this._repository);

  final CatalogsRepository _repository;

  @override
  Future<List<CatalogDepartment>> call(NoParams params) =>
      _repository.getDepartments();
}

/// Municipios del departamento con ese id.
class GetCities implements UseCase<List<CatalogCity>, String> {
  const GetCities(this._repository);

  final CatalogsRepository _repository;

  @override
  Future<List<CatalogCity>> call(String departmentId) =>
      _repository.getCities(departmentId);
}
