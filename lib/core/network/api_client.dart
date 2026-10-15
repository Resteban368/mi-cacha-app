import 'package:dio/dio.dart';

import '../session/session_manager.dart';
import '../session/write_access.dart';
import 'api_config.dart';

/// Cliente HTTP de la API con el token de la sesión, manejo de 401 y del
/// modo solo lectura (403 `SUBSCRIPTION_INACTIVE`).
Dio buildApiClient(SessionManager session, [WriteAccess? writeAccess]) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.add(AuthInterceptor(session, writeAccess));
  return dio;
}

/// Adjunta `Authorization: Bearer <token>` y, si una petición autenticada
/// recibe 401, da la sesión por vencida (el router vuelve al login). Un 403
/// `SUBSCRIPTION_INACTIVE` pasa la app a solo lectura.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._session, [this._writeAccess]);

  final SessionManager _session;
  final WriteAccess? _writeAccess;

  static const subscriptionInactive = 'SUBSCRIPTION_INACTIVE';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _session.accessToken;
    if (token != null && options.extra[ApiConfig.skipAuth] != true) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final sentToken = err.requestOptions.headers.containsKey('Authorization');
    final response = err.response;
    if (response?.statusCode == 401 && sentToken) {
      await _session.expire();
    }
    final isInactivePlan = switch (response?.data) {
      {'code': subscriptionInactive} => true,
      _ => false,
    };
    if (response?.statusCode == 403 && isInactivePlan) {
      _writeAccess?.update(canWrite: false);
    }
    handler.next(err);
  }
}
