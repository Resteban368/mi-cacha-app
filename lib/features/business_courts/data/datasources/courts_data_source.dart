import '../../../../core/media/image_upload.dart';
import '../../domain/entities/court.dart';

abstract interface class CourtsDataSource {
  Future<List<Court>> getCourts();

  Future<Court> create(CourtDraft draft);

  Future<Court> update(String courtId, CourtDraft draft);

  Future<Court> removePhoto(String courtId, CourtPhotoSlot slot);

  Future<Court> uploadPhoto(
    String courtId,
    CourtPhotoSlot slot,
    ImageUpload image,
  );
}
