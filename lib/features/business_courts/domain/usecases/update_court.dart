import '../../../../core/usecase/usecase.dart';
import '../entities/court.dart';
import '../entities/court_failure.dart';
import '../repositories/courts_repository.dart';
import 'create_court.dart';

typedef UpdateCourtParams = ({String courtId, CourtDraft draft});

class UpdateCourt implements UseCase<Court, UpdateCourtParams> {
  const UpdateCourt(this._repository);

  final CourtsRepository _repository;

  @override
  Future<Court> call(UpdateCourtParams params) async {
    final error = CreateCourt.validate(params.draft);
    if (error != null) {
      throw CourtException(CourtFailure.invalid, message: error);
    }
    return _repository.update(params.courtId, params.draft);
  }
}
