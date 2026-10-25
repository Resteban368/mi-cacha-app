import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/network/api_client.dart';
import 'package:mi_cancha/core/network/api_config.dart';
import 'package:mi_cancha/core/network/api_exception.dart';
import 'package:mi_cancha/core/session/session.dart';
import 'package:mi_cancha/core/session/session_manager.dart';
import 'package:mi_cancha/core/session/session_storage.dart';
import 'package:mi_cancha/core/session/write_access.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_http_adapter.dart';

class _MockStorage extends Mock implements SessionStorage {}

const admin = Session(
  accessToken: 'tok',
  role: 'ADMIN_NEGOCIO',
  displayName: 'Andrés',
);

void main() {
  setUpAll(() => registerFallbackValue(admin));

  late SessionManager session;
  late FakeHttpAdapter adapter;
  late Dio dio;
  late WriteAccess writeAccess;

  setUp(() {
    final storage = _MockStorage();
    when(() => storage.read()).thenAnswer((_) async => null);
    when(() => storage.write(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
    session = SessionManager(storage);
    adapter = FakeHttpAdapter((_) => (200, {'ok': true}));
    writeAccess = WriteAccess();
    dio = buildApiClient(session, writeAccess)..httpClientAdapter = adapter;
  });

  test('usa la URL base de la API', () {
    expect(dio.options.baseUrl, ApiConfig.baseUrl);
    expect(ApiConfig.baseUrl, 'https://app.micanchaapp.com/api/v1');
  });

  group('AuthInterceptor', () {
    test('adjunta el token de la sesión', () async {
      await session.start(admin);
      await dio.get<void>('/auth/me');
      expect(adapter.requests.single.headers['Authorization'], 'Bearer tok');
    });

    test('no adjunta token sin sesión ni con skipAuth', () async {
      await dio.get<void>('/catalogs');
      await session.start(admin);
      await dio.post<void>(
        '/auth/business/login',
        options: Options(extra: {ApiConfig.skipAuth: true}),
      );
      for (final request in adapter.requests) {
        expect(request.headers.containsKey('Authorization'), isFalse);
      }
    });

    test('un 401 con token vence la sesión', () async {
      await session.start(admin);
      adapter.handler = (_) => (401, {'message': 'Token inválido o expirado'});

      await expectLater(
        dio.get<void>('/business/profile'),
        throwsA(isA<DioException>()),
      );
      expect(session.current, isNull);
      expect(session.consumeExpired(), isTrue);
    });

    test('un 403 SUBSCRIPTION_INACTIVE pasa a solo lectura', () async {
      await session.start(admin);
      adapter.handler = (_) => (
        403,
        {
          'statusCode': 403,
          'code': 'SUBSCRIPTION_INACTIVE',
          'message': 'Tu plan no está activo',
        },
      );
      await expectLater(
        dio.post<void>('/business/reservations'),
        throwsA(isA<DioException>()),
      );
      expect(writeAccess.canWrite, isFalse);
      // No vence la sesión: se puede seguir consultando.
      expect(session.current, admin);
    });

    test('otro 403 no cambia el modo', () async {
      adapter.handler = (_) => (403, {'message': 'Sin permiso'});
      await expectLater(
        dio.get<void>('/business/profile'),
        throwsA(isA<DioException>()),
      );
      expect(writeAccess.canWrite, isTrue);
    });

    test('un 401 sin token (login fallido) no toca la sesión', () async {
      adapter.handler = (_) => (401, {'message': 'Credenciales inválidas'});
      await expectLater(
        dio.post<void>(
          '/auth/business/login',
          options: Options(extra: {ApiConfig.skipAuth: true}),
        ),
        throwsA(isA<DioException>()),
      );
      expect(session.consumeExpired(), isFalse);
    });
  });

  group('ApiException.fromDio', () {
    Future<ApiException> errorFor((int, Object?) response) async {
      adapter.handler = (_) => response;
      try {
        await dio.get<void>('/x');
      } on DioException catch (e) {
        return ApiException.fromDio(e);
      }
      throw StateError('no falló');
    }

    test('clasifica por código y lee el mensaje de NestJS', () async {
      final unauthorized = await errorFor((
        401,
        {'message': 'Credenciales inválidas', 'statusCode': 401},
      ));
      expect(unauthorized.kind, ApiErrorKind.unauthorized);
      expect(unauthorized.message, 'Credenciales inválidas');

      final badRequest = await errorFor((
        400,
        {
          'message': ['email must be an email', 'password should not be empty'],
        },
      ));
      expect(badRequest.kind, ApiErrorKind.badRequest);
      expect(
        badRequest.message,
        'email must be an email\npassword should not be empty',
      );

      expect((await errorFor((403, null))).kind, ApiErrorKind.forbidden);
      expect((await errorFor((404, null))).kind, ApiErrorKind.notFound);
      expect((await errorFor((503, 'html'))).kind, ApiErrorKind.server);
    });

    test('sin conexión es un error de red', () async {
      adapter.handler = offline;
      try {
        await dio.get<void>('/x');
        fail('no falló');
      } on DioException catch (e) {
        expect(ApiException.fromDio(e).kind, ApiErrorKind.network);
      }
    });
  });
}
