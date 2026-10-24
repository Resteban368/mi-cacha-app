import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/location/geo_point.dart';
import 'package:mi_cancha/core/network/api_exception.dart';
import 'package:mi_cancha/features/business_profile/data/datasources/business_api_data_source.dart';
import 'package:mi_cancha/features/business_profile/domain/entities/business.dart';
import 'package:mi_cancha/core/media/image_upload.dart';

import '../../../helpers/api_dio.dart';
import '../../../helpers/fake_http_adapter.dart';

void main() {
  // Respuesta real de GET /business/profile.
  final profileJson = {
    'id': 'a3863b10',
    'name': 'cancha dev',
    'address': 'Calle 25 # 11-82',
    'neighborhood': 'torasso',
    'description': null,
    'amenities': ['WIFI', 'PARQUEADERO', 'NUEVO_SERVICIO'],
  };

  late FakeHttpAdapter adapter;
  late BusinessApiDataSource source;

  setUp(() {
    adapter = FakeHttpAdapter((_) => (200, profileJson));
    source = BusinessApiDataSource(apiDio(adapter));
  });

  test('lee el perfil con los códigos de servicios tal cual', () async {
    final business = await source.getMyBusiness();
    expect(business!.name, 'cancha dev');
    expect(business.description, isNull);
    expect(business.amenities, {'WIFI', 'PARQUEADERO', 'NUEVO_SERVICIO'});
    expect(adapter.requests.single.path, '/business/profile');
  });

  test('404 = aún no registró su negocio (estado vacío)', () async {
    adapter.handler = (_) => (
      404,
      {'message': 'Aún no has registrado tu negocio', 'statusCode': 404},
    );
    expect(await source.getMyBusiness(), isNull);
  });

  test('otros errores se propagan', () async {
    adapter.handler = offline;
    await expectLater(source.getMyBusiness(), throwsA(isA<ApiException>()));
  });

  test(
    'guarda con PUT, códigos de servicios y sin descripción vacía',
    () async {
      await source.save(
        const BusinessDraft(
          name: ' El Golazo ',
          address: 'Calle 15 # 8-32',
          neighborhood: 'Centro',
          description: '  ',
          amenities: {'ILUMINACION_LED'},
        ),
      );

      final request = adapter.requests.single;
      expect(request.method, 'PUT');
      expect(request.path, '/business/profile');
      final body = request.data is String
          ? jsonDecode(request.data as String)
          : request.data;
      expect(body, {
        'name': 'El Golazo',
        'address': 'Calle 15 # 8-32',
        'neighborhood': 'Centro',
        'amenities': ['ILUMINACION_LED'],
      });
    },
  );

  test(
    'la foto llega por HTTPS aunque la API arme el enlace con http',
    () async {
      adapter.handler = (_) => (
        200,
        {...profileJson, 'imageUrl': 'http://mi-cancha-api.vercel.app/x/1'},
      );
      final business = await source.getMyBusiness();
      expect(business!.imageUrl, 'https://mi-cancha-api.vercel.app/x/1');
    },
  );

  group('galería de fotos', () {
    const url1 = 'http://mi-cancha-api.vercel.app/api/v1/images/business/p1';
    const url2 = 'https://mi-cancha-api.vercel.app/api/v1/images/business/p2';
    final withPhotos = {
      ...profileJson,
      'imageUrl': url1,
      'photos': [
        {'id': 'p1', 'url': url1},
        {'id': 'p2', 'url': url2},
        {'id': 'sin-url'},
      ],
    };

    test('lee las fotos en orden y por HTTPS', () async {
      adapter.handler = (_) => (200, withPhotos);
      final business = await source.getMyBusiness();

      expect(business!.photos, const [
        BusinessPhoto(
          id: 'p1',
          url: 'https://mi-cancha-api.vercel.app/api/v1/images/business/p1',
        ),
        BusinessPhoto(id: 'p2', url: url2),
      ]);
      // La portada es la primera.
      expect(business.imageUrl, business.photos.first.url);
      expect(business.canAddPhoto, isTrue);
    });

    test('sin "photos" (API anterior) la galería queda vacía', () async {
      final business = await source.getMyBusiness();
      expect(business!.photos, isEmpty);
      expect(business.imageUrl, isNull);
    });

    test('agrega con POST multipart en el campo image', () async {
      adapter.handler = (_) => (200, withPhotos);
      final business = await source.addPhoto(
        ImageUpload(
          bytes: Uint8List.fromList([
            0x89,
            0x50,
            0x4e,
            0x47,
            0x0d,
            0x0a,
            0x1a,
            0x0a,
          ]),
          fileName: 'sede.png',
        ),
      );

      expect(business.photos, hasLength(2));
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/business/profile/photos');
      final form = request.data as FormData;
      final (field, file) = (form.files.single.key, form.files.single.value);
      expect(field, 'image');
      expect(file.filename, 'sede.png');
      expect(file.contentType.toString(), 'image/png');
    });

    test('quita con DELETE /photos/:id', () async {
      await source.removePhoto('p2');
      expect(adapter.requests.single.method, 'DELETE');
      expect(adapter.requests.single.path, '/business/profile/photos/p2');
    });

    test('ordena con PUT /photos/order y todos los ids', () async {
      await source.reorderPhotos(['p2', 'p1']);

      final request = adapter.requests.single;
      expect(request.method, 'PUT');
      expect(request.path, '/business/profile/photos/order');
      final body = request.data is String
          ? jsonDecode(request.data as String)
          : request.data;
      expect(body, {
        'ids': ['p2', 'p1'],
      });
    });
  });

  test('envía y lee el punto de llegada', () async {
    adapter.handler = (_) =>
        (200, {...profileJson, 'latitude': 4.6097, 'longitude': -74.0817});

    final saved = await source.save(
      const BusinessDraft(
        name: 'El Golazo',
        address: 'Calle 15 # 8-32',
        neighborhood: 'Centro',
        location: GeoPoint(4.6097, -74.0817),
      ),
    );

    final request = adapter.requests.single;
    final body = request.data is String
        ? jsonDecode(request.data as String)
        : request.data;
    expect(body['latitude'], 4.6097);
    expect(body['longitude'], -74.0817);
    expect(saved.location, const GeoPoint(4.6097, -74.0817));
  });

  test('sin ubicación no envía coordenadas y lee null', () async {
    await source.save(
      const BusinessDraft(
        name: 'El Golazo',
        address: 'Calle 15',
        neighborhood: 'Centro',
      ),
    );
    final request = adapter.requests.single;
    final body = request.data is String
        ? jsonDecode(request.data as String)
        : request.data;
    expect((body as Map).containsKey('latitude'), isFalse);
    expect((await source.getMyBusiness())!.location, isNull);
  });
}
