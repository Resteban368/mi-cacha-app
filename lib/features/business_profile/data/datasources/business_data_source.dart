import '../../domain/entities/business.dart';
import '../../domain/entities/online_booking_link.dart';
import '../../../../core/media/image_upload.dart';

abstract interface class BusinessDataSource {
  Future<Business?> getMyBusiness();

  Future<Business> save(BusinessDraft draft);

  Future<Business> addPhoto(ImageUpload image);

  Future<Business> removePhoto(String photoId);

  /// [ids] trae todas las fotos, sin repetir, en el orden deseado.
  Future<Business> reorderPhotos(List<String> ids);

  Future<OnlineBookingLink> getOnlineBookingLink();
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
      photos: _business?.photos ?? const [],
      location: draft.location,
      city: _business?.city,
    );
  }

  @override
  Future<Business> addPhoto(ImageUpload image) async {
    await Future<void>.delayed(latency);
    final photos = _requireBusiness().photos;
    return _business = _withPhotos([
      ...photos,
      BusinessPhoto(
        id: 'p${DateTime.now().microsecondsSinceEpoch}',
        url: 'https://fotos.test/${image.fileName}',
      ),
    ]);
  }

  @override
  Future<Business> removePhoto(String photoId) async {
    await Future<void>.delayed(latency);
    return _business = _withPhotos([
      for (final photo in _requireBusiness().photos)
        if (photo.id != photoId) photo,
    ]);
  }

  @override
  Future<Business> reorderPhotos(List<String> ids) async {
    await Future<void>.delayed(latency);
    final byId = {for (final p in _requireBusiness().photos) p.id: p};
    return _business = _withPhotos([for (final id in ids) ?byId[id]]);
  }

  @override
  Future<OnlineBookingLink> getOnlineBookingLink() async {
    await Future<void>.delayed(latency);
    final business = _requireBusiness();
    return OnlineBookingLink(
      url: 'https://mi-cancha.test/reservar/${business.id}',
      slug: business.id,
      enabled: true,
      bookingAvailable: true,
    );
  }

  Business _requireBusiness() =>
      _business ?? (throw StateError('Aún no hay negocio'));

  Business _withPhotos(List<BusinessPhoto> photos) {
    final business = _requireBusiness();
    return Business(
      id: business.id,
      name: business.name,
      address: business.address,
      neighborhood: business.neighborhood,
      description: business.description,
      amenities: business.amenities,
      imageUrl: photos.firstOrNull?.url,
      photos: List.unmodifiable(photos),
      location: business.location,
      city: business.city,
    );
  }
}
