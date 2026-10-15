import 'package:dio/dio.dart';

enum ApiErrorKind {
  /// Sin conexión, DNS o tiempo de espera agotado.
  network,

  /// 401: credenciales inválidas o sesión vencida.
  unauthorized,
  forbidden,
  badRequest,
  notFound,

  /// 409: el registro ya existe (p. ej. nombre de cancha repetido).
  conflict,
  server,
  unknown,
}

/// Error de la API ya clasificado. El backend (NestJS) responde
/// `{message, error, statusCode}`, donde `message` puede ser texto o lista.
class ApiException implements Exception {
  const ApiException(this.kind, {this.statusCode, this.message, this.code});

  factory ApiException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final kind = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => ApiErrorKind.network,
      _ => switch (status) {
        401 => ApiErrorKind.unauthorized,
        403 => ApiErrorKind.forbidden,
        400 || 422 => ApiErrorKind.badRequest,
        404 => ApiErrorKind.notFound,
        409 => ApiErrorKind.conflict,
        final int code when code >= 500 => ApiErrorKind.server,
        _ => ApiErrorKind.unknown,
      },
    };
    return ApiException(
      kind,
      statusCode: status,
      message: _messageOf(error.response?.data),
      code: switch (error.response?.data) {
        {'code': final String code} => code,
        _ => null,
      },
    );
  }

  final ApiErrorKind kind;
  final int? statusCode;

  /// Mensaje del backend. Solo se muestra en la UI cuando el backend lo
  /// escribe para el usuario (validaciones de canchas, límite del plan).
  final String? message;

  /// Código de negocio del backend, p. ej. `PLAN_LIMIT_REACHED`.
  final String? code;

  static String? _messageOf(Object? data) {
    if (data is! Map) return null;
    return switch (data['message']) {
      final String text => text,
      final List<dynamic> list => list.join('\n'),
      _ => null,
    };
  }

  @override
  String toString() => 'ApiException($kind, $statusCode, $code, $message)';
}

/// Ejecuta una llamada a la API y convierte los errores de `dio` en
/// [ApiException].
Future<T> apiCall<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (error) {
    throw ApiException.fromDio(error);
  }
}
