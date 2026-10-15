import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/network/api_exception.dart';
import 'package:mi_cancha/features/auth/data/datasources/business_auth_api_data_source.dart';
import 'package:mi_cancha/features/auth/domain/entities/email_credentials.dart';

import '../../../helpers/fake_http_adapter.dart';

void main() {
  const credentials = EmailCredentials(
    email: 'admin@golazo.co',
    password: 'secreto',
  );

  late FakeHttpAdapter adapter;
  late BusinessAuthApiDataSourceImpl dataSource;

  setUp(() {
    adapter = FakeHttpAdapter(
      (_) => (
        201,
        {
          'accessToken': 'eyJ.token',
          'user': {
            'id': 'u1',
            'displayName': 'Andrés Gómez',
            'role': 'ADMIN_NEGOCIO',
          },
        },
      ),
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = adapter;
    dataSource = BusinessAuthApiDataSourceImpl(dio);
  });

  test('envía POST /auth/business/login y lee token y usuario', () async {
    final response = await dataSource.login(credentials);

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(
      request.uri.toString(),
      'https://api.test/api/v1/auth/business/login',
    );
    expect(
      request.data is String
          ? jsonDecode(request.data as String)
          : request.data,
      {'email': 'admin@golazo.co', 'password': 'secreto'},
    );
    expect(response.accessToken, 'eyJ.token');
    expect(response.id, 'u1');
    expect(response.displayName, 'Andrés Gómez');
    expect(response.role, 'ADMIN_NEGOCIO');
  });

  test('credenciales inválidas → ApiException unauthorized', () async {
    adapter.handler = (_) => (
      401,
      {
        'message': 'Credenciales inválidas',
        'error': 'Unauthorized',
        'statusCode': 401,
      },
    );
    await expectLater(
      dataSource.login(credentials),
      throwsA(
        isA<ApiException>().having(
          (e) => e.kind,
          'kind',
          ApiErrorKind.unauthorized,
        ),
      ),
    );
  });

  test('sin conexión → ApiException network', () async {
    adapter.handler = offline;
    await expectLater(
      dataSource.login(credentials),
      throwsA(
        isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.network),
      ),
    );
  });

  test('respuesta sin token → ApiException server', () async {
    adapter.handler = (_) => (200, {'user': {}});
    await expectLater(
      dataSource.login(credentials),
      throwsA(
        isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.server),
      ),
    );
  });
}
