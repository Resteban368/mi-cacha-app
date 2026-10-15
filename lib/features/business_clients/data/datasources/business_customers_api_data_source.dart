import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/client_profile.dart';
import '../../domain/entities/customer_payload.dart';
import '../../domain/entities/customer_query.dart';
import '../../domain/entities/customers_page_result.dart';
import 'business_customers_data_source.dart';

/// Implementación remota basada en Dio para la gestión de clientes en la API de Mi Cancha.
class BusinessCustomersApiDataSource implements BusinessCustomersDataSource {
  const BusinessCustomersApiDataSource(this._dio);

  final Dio _dio;

  static const _path = '/business/customers';

  @override
  Future<CustomersPageResult> getCustomers(CustomerQuery query) async {
    final response = await apiCall(
      () => _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: query.toQueryParams(),
      ),
    );
    return CustomersPageResult.fromJson(response.data!);
  }

  @override
  Future<ClientProfile> createCustomer(CustomerPayload payload) async {
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(
        _path,
        data: payload.toJson(),
      ),
    );
    return ClientProfile.fromJson(response.data!);
  }

  @override
  Future<ClientProfile> updateCustomer(
    String id,
    CustomerPayload payload,
  ) async {
    final response = await apiCall(
      () => _dio.patch<Map<String, dynamic>>(
        '$_path/$id',
        data: payload.toJson(),
      ),
    );
    return ClientProfile.fromJson(response.data!);
  }
}
