import '../../domain/entities/business.dart';
import '../../../../core/media/image_upload.dart';

abstract interface class BusinessDataSource {
  Future<Business?> getMyBusiness();

  Future<Business> save(BusinessDraft draft);

  Future<Business> uploadCover(ImageUpload image);

  Future<Business> removeCover();
}

/// Negocio en memoria mientras la API está en construcción: arranca vacío
/// (estado "Crear negocio") y conserva lo guardado durante la sesión.
/// TODO: reemplazar por la API (HTTPS) + caché local para modo offline.
class FakeBusinessDataSource implements BusinessDataSource {
  FakeBusinessDataSource({this.latency = const Duration(milliseconds: 600)});

  final Duration latency;
  Business? _business;

  @override
  Future<Business?> getMyBusiness() async {
    await Future<void>.delayed(latency);
    return _business;
  }

  @override
  Future<Business> save(BusinessDraft draft) async {
    await Future<void>.delayed(latency);
    final description = draft.description?.trim();
    return _business = Business(
      id: _business?.id ?? 'b1',
      name: draft.name.trim(),
      address: draft.address.trim(),
      neighborhood: draft.neighborhood.trim(),
      description: (description?.isEmpty ?? true) ? null : description,
      amenities: Set.unmodifiable(draft.amenities),
      imageUrl: _business?.imageUrl,
      location: draft.location,
    );
  }

  @override
  Future<Business> uploadCover(ImageUpload image) async {
    await Future<void>.delayed(latency);
    return _business = _withImage('https://fotos.test/${image.fileName}');
  }

  @override
  Future<Business> removeCover() async {
    await Future<void>.delayed(latency);
    return _business = _withImage(null);
  }

  Business _withImage(String? imageUrl) {
    final business = _business;
    if (business == null) throw StateError('Aún no hay negocio');
    return Business(
      id: business.id,
      name: business.name,
      address: business.address,
      neighborhood: business.neighborhood,
      description: business.description,
      amenities: business.amenities,
      imageUrl: imageUrl,
      location: business.location,
    );
  }
}
