import 'package:dio/dio.dart';

import '../../../../core/location/geo_point.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/business.dart';
import '../../../../core/media/image_upload.dart';
import 'business_data_source.dart';

/// Perfil del negocio en la API (`/business/profile`).
class BusinessApiDataSource implements BusinessDataSource {
  const BusinessApiDataSource(this._dio);

  final Dio _dio;

  static const _path = '/business/profile';
  static const _photosPath = '$_path/photos';

  @override
  Future<Business?> getMyBusiness() async {
    try {
      final response = await apiCall(
        () => _dio.get<Map<String, dynamic>>(_path),
      );
      return _fromJson(response.data!);
    } on ApiException catch (error) {
      // 404: el administrador aún no registró su negocio (estado vacío).
      if (error.kind == ApiErrorKind.notFound) return null;
      rethrow;
    }
  }

  /// Es un PUT: se manda siempre el objeto completo. Una descripción vacía
  /// se omite y la API la borra; sin servicios se envía `[]`.
  @override
  Future<Business> save(BusinessDraft draft) async {
    final description = draft.description?.trim();
    final response = await apiCall(
      () => _dio.put<Map<String, dynamic>>(
        _path,
        data: {
          'name': draft.name.trim(),
          'address': draft.address.trim(),
          'neighborhood': draft.neighborhood.trim(),
          if (description != null && description.isNotEmpty)
            'description': description,
          'amenities': draft.amenities.toList(),
          // Sin ubicación se omiten y la API la borra (es un PUT).
          if (draft.location case final location?) ...{
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
        },
      ),
    );
    return _fromJson(response.data!);
  }

  /// Multipart en el campo `image`. Se sube desde bytes (no `fromFile`)
  /// para que funcione también en web.
  @override
  Future<Business> addPhoto(ImageUpload image) async {
    final form = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        image.bytes,
        filename: image.fileName,
        contentType: DioMediaType('image', image.isPng ? 'png' : 'jpeg'),
      ),
    });
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(_photosPath, data: form),
    );
    return _fromJson(response.data!);
  }

  @override
  Future<Business> removePhoto(String photoId) async {
    final response = await apiCall(
      () => _dio.delete<Map<String, dynamic>>('$_photosPath/$photoId'),
    );
    return _fromJson(response.data!);
  }

  @override
  Future<Business> reorderPhotos(List<String> ids) async {
    final response = await apiCall(
      () => _dio.put<Map<String, dynamic>>(
        '$_photosPath/order',
        data: {'ids': ids},
      ),
    );
    return _fromJson(response.data!);
  }

  /// `photos` puede no venir (API anterior): queda la lista vacía.
  static Business _fromJson(Map<String, dynamic> json) => Business(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    neighborhood: json['neighborhood'] as String,
    description: json['description'] as String?,
    amenities: {
      for (final code in (json['amenities'] as List<dynamic>? ?? const []))
        '$code',
    },
    location: switch ((json['latitude'], json['longitude'])) {
      (final num lat, final num lng) => GeoPoint(
        lat.toDouble(),
        lng.toDouble(),
      ),
      _ => null,
    },
    imageUrl: switch (json['imageUrl']) {
      final String url => ApiConfig.secureUrl(url),
      _ => null,
    },
    photos: [
      for (final photo in (json['photos'] as List<dynamic>? ?? const []))
        if (photo case {'id': final String id, 'url': final String url})
          BusinessPhoto(id: id, url: ApiConfig.secureUrl(url)),
    ],
  );
}
