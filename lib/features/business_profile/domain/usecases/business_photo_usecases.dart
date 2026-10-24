import '../../../../core/media/image_upload.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/business.dart';
import '../repositories/business_repository.dart';

class AddBusinessPhoto implements UseCase<Business, ImageUpload> {
  const AddBusinessPhoto(this._repository);

  final BusinessRepository _repository;

  /// Lanza [ImageUploadException] si la foto no cumple los límites de la API,
  /// sin llegar a subirla.
  @override
  Future<Business> call(ImageUpload image) {
    final error = image.error;
    if (error != null) throw ImageUploadException(error);
    return _repository.addPhoto(image);
  }
}

class RemoveBusinessPhoto implements UseCase<Business, String> {
  const RemoveBusinessPhoto(this._repository);

  final BusinessRepository _repository;

  @override
  Future<Business> call(String photoId) => _repository.removePhoto(photoId);
}

class ReorderBusinessPhotos implements UseCase<Business, List<String>> {
  const ReorderBusinessPhotos(this._repository);

  final BusinessRepository _repository;

  @override
  Future<Business> call(List<String> ids) => _repository.reorderPhotos(ids);
}
