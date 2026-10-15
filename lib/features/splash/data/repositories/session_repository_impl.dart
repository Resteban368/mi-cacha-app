import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/session/session_manager.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../domain/repositories/session_repository.dart';

class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(
    this._session,
    this._dio, {
    this.verifyTimeout = const Duration(seconds: 6),
  });

  final SessionManager _session;
  final Dio _dio;

  /// Tiempo máximo para verificar el token sin demorar el splash.
  final Duration verifyTimeout;

  /// Verifica el token guardado con `GET /auth/me`:
  /// - válido → rol que informa la API;
  /// - 401 → la sesión venció (el interceptor la cierra) → `null`;
  /// - sin conexión, lento o error del servidor → se confía en la sesión
  ///   guardada (modo offline); si luego vence, el 401 lleva al login.
  @override
  Future<UserRole?> activeRole() async {
    final session = await _session.restore();
    if (session == null) return null;
    try {
      final response = await apiCall(
        () => _dio.get<Map<String, dynamic>>('/auth/me'),
      ).timeout(verifyTimeout);
      return UserRole.fromApi(response.data?['role'] as String?);
    } on ApiException catch (error) {
      if (error.kind == ApiErrorKind.unauthorized) return null;
      return UserRole.fromApi(session.role);
    } on TimeoutException {
      return UserRole.fromApi(session.role);
    }
  }
}
