import '../../../../core/usecase/usecase.dart';
import '../entities/business.dart';
import '../repositories/business_repository.dart';

class RemoveBusinessCover implements UseCase<Business, NoParams> {
  const RemoveBusinessCover(this._repository);

  final BusinessRepository _repository;

  @override
  Future<Business> call(NoParams params) => _repository.removeCover();
}
