import '../../../../core/media/image_upload.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/court.dart';
import '../repositories/courts_repository.dart';

typedef UploadCourtPhotoParams = ({
  String courtId,
  CourtPhotoSlot slot,
  ImageUpload image,
});

class UploadCourtPhoto implements UseCase<Court, UploadCourtPhotoParams> {
  const UploadCourtPhoto(this._repository);

  final CourtsRepository _repository;

  /// Lanza [ImageUploadException] si la foto no cumple los límites de la
  /// API (JPG/PNG de hasta 4 MB), sin llegar a subirla.
  @override
  Future<Court> call(UploadCourtPhotoParams params) async {
    final error = params.image.error;
    if (error != null) throw ImageUploadException(error);
    return _repository.uploadPhoto(params.courtId, params.slot, params.image);
  }
}
