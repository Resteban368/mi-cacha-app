import '../../../../core/usecase/usecase.dart';
import '../repositories/app_info_repository.dart';

class GetAppVersion implements UseCase<String, NoParams> {
  const GetAppVersion(this._repository);

  final AppInfoRepository _repository;

  @override
  Future<String> call(NoParams params) => _repository.getVersion();
}
