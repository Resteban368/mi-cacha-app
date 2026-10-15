import '../../../../core/media/image_upload.dart';
import '../entities/court.dart';

/// Lanza `CourtException` cuando la API rechaza la operación.
abstract interface class CourtsRepository {
  /// Canchas del negocio, en el orden de la API.
  Future<List<Court>> getCourts();

  Future<Court> create(CourtDraft draft);

  /// Reemplaza los datos de la cancha (horario y tarifas completos).
  Future<Court> update(String courtId, CourtDraft draft);

  Future<Court> removePhoto(String courtId, CourtPhotoSlot slot);

  /// Sube o reemplaza la foto de [slot]; devuelve la cancha actualizada.
  Future<Court> uploadPhoto(
    String courtId,
    CourtPhotoSlot slot,
    ImageUpload image,
  );
}
