import '../../../usecase/usecase.dart';
import '../entities/app_catalogs.dart';
import '../repositories/catalogs_repository.dart';

class GetCatalogs implements UseCase<AppCatalogs, NoParams> {
  const GetCatalogs(this._repository);

  final CatalogsRepository _repository;

  @override
  Future<AppCatalogs> call(NoParams params) => _repository.getCatalogs();
}
