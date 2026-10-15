import '../../../../core/usecase/usecase.dart';
import '../entities/court.dart';
import '../repositories/courts_repository.dart';

class GetCourts implements UseCase<List<Court>, NoParams> {
  const GetCourts(this._repository);

  final CourtsRepository _repository;

  @override
  Future<List<Court>> call(NoParams params) => _repository.getCourts();
}
