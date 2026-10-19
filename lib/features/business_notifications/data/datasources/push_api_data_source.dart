import 'package:dio/dio.dart';

import '../../domain/entities/push_exception.dart';
import 'browser_push_contract.dart';

/// Endpoints de avisos del negocio (con el JWT del negocio).
class PushApiDataSource {
  const PushApiDataSource(this._dio);

  final Dio _dio;

  /// Clave pública VAPID, o `null` si el servidor no tiene push (404).
  Future<String?> fetchPublicKey() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/business/notifications/vapid-key',
      );
      return response.data?['publicKey'] as String?;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      throw _failure(error);
    }
  }

  Future<void> saveSubscription(BrowserSubscription subscription) async {
    try {
      await _dio.post<void>(
        '/business/notifications/subscriptions',
        data: {
          'endpoint': subscription.endpoint,
          'keys': {'p256dh': subscription.p256dh, 'auth': subscription.auth},
        },
      );
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  Future<void> deleteSubscription(String endpoint) async {
    try {
      await _dio.delete<void>(
        '/business/notifications/subscriptions',
        data: {'endpoint': endpoint},
      );
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  /// Baja sin sesión (cierre de sesión o token vencido): basta el endpoint,
  /// que es un secreto de este navegador.
  Future<void> forgetSubscription(String endpoint) async {
    try {
      await _dio.delete<void>(
        '/public/notifications/subscriptions',
        data: {'endpoint': endpoint},
      );
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  static PushException _failure(DioException error) =>
      PushException(switch (error.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout => PushFailure.network,
        _ => PushFailure.server,
      });
}
