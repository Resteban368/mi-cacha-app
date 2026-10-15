import '../../../../core/usecase/usecase.dart';
import '../entities/business.dart';
import '../../../../core/media/image_upload.dart';
import '../repositories/business_repository.dart';

class UploadBusinessCover implements UseCase<Business, ImageUpload> {
  const UploadBusinessCover(this._repository);

  final BusinessRepository _repository;

  /// Lanza [ImageUploadException] si la foto no cumple los límites de la API,
  /// sin llegar a subirla.
  @override
  Future<Business> call(ImageUpload image) {
    final error = image.error;
    if (error != null) throw ImageUploadException(error);
    return _repository.uploadCover(image);
  }
}
