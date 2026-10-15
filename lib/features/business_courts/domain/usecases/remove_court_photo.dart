import '../../../../core/usecase/usecase.dart';
import '../entities/court.dart';
import '../repositories/courts_repository.dart';

typedef RemoveCourtPhotoParams = ({String courtId, CourtPhotoSlot slot});

class RemoveCourtPhoto implements UseCase<Court, RemoveCourtPhotoParams> {
  const RemoveCourtPhoto(this._repository);

  final CourtsRepository _repository;

  @override
  Future<Court> call(RemoveCourtPhotoParams params) =>
      _repository.removePhoto(params.courtId, params.slot);
}
