import '../entities/business.dart';
import '../../../../core/media/image_upload.dart';

abstract interface class BusinessRepository {
  /// Negocio del administrador; `null` si aún no lo ha creado.
  Future<Business?> getMyBusiness();

  /// Crea el negocio o, si ya existe, actualiza sus datos.
  Future<Business> save(BusinessDraft draft);

  /// Sube o reemplaza la foto de portada; devuelve el negocio actualizado.
  Future<Business> uploadCover(ImageUpload image);

  /// Quita la foto de portada; devuelve el negocio actualizado.
  Future<Business> removeCover();
}
