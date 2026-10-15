import 'package:dio/dio.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/email_credentials.dart';

/// Respuesta del login: token y datos básicos del usuario.
typedef BusinessLoginResponse = ({
  String accessToken,
  String id,
  String displayName,
  String role,
});

abstract interface class BusinessAuthApiDataSource {
  /// `POST /auth/business/login`. Lanza [ApiException].
  Future<BusinessLoginResponse> login(EmailCredentials credentials);
}

class BusinessAuthApiDataSourceImpl implements BusinessAuthApiDataSource {
  const BusinessAuthApiDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<BusinessLoginResponse> login(EmailCredentials credentials) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/business/login',
        data: {'email': credentials.email, 'password': credentials.password},
        options: Options(extra: {ApiConfig.skipAuth: true}),
      );
      final body = response.data;
      final token = body?['accessToken'];
      final user = body?['user'];
      if (token is! String || token.isEmpty || user is! Map) {
        throw const ApiException(
          ApiErrorKind.server,
          message: 'Respuesta de login sin token o usuario',
        );
      }
      return (
        accessToken: token,
        id: '${user['id'] ?? ''}',
        displayName: '${user['displayName'] ?? ''}',
        role: '${user['role'] ?? ''}',
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
