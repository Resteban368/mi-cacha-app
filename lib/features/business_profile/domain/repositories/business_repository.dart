import '../entities/business.dart';
import '../../../../core/media/image_upload.dart';

abstract interface class BusinessRepository {
  /// Negocio del administrador; `null` si aún no lo ha creado.
  Future<Business?> getMyBusiness();

  /// Crea el negocio o, si ya existe, actualiza sus datos.
  Future<Business> save(BusinessDraft draft);

  /// Agrega una foto al final de la galería (máximo
  /// [Business.maxPhotos]); devuelve el negocio actualizado.
  Future<Business> addPhoto(ImageUpload image);

  /// Quita una foto de la galería; devuelve el negocio actualizado.
  Future<Business> removePhoto(String photoId);

  /// Reordena la galería: [ids] trae todas las fotos, sin repetir; la
  /// primera queda de portada. Devuelve el negocio actualizado.
  Future<Business> reorderPhotos(List<String> ids);
}
