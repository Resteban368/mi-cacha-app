import 'package:dio/dio.dart';

import '../../../network/api_exception.dart';
import '../../domain/entities/app_catalogs.dart';
import '../../domain/entities/catalog_geography.dart';
import 'catalogs_data_source.dart';

/// Catálogos en la API (`GET /catalogs`) y la división política de
/// Colombia (`/catalogs/departments`).
class CatalogsApiDataSource implements CatalogsDataSource {
  const CatalogsApiDataSource(this._dio);

  final Dio _dio;

  static const _path = '/catalogs';

  @override
  Future<AppCatalogs> getCatalogs() async {
    final response = await apiCall(() => _dio.get<Map<String, dynamic>>(_path));
    return AppCatalogs.fromJson(response.data!);
  }

  @override
  Future<List<CatalogDepartment>> getDepartments() async {
    final response = await apiCall(
      () => _dio.get<List<dynamic>>('$_path/departments'),
    );
    return [
      for (final item in response.data ?? const [])
        CatalogDepartment.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<CatalogCity>> getCities(String departmentId) async {
    final response = await apiCall(
      () => _dio.get<List<dynamic>>('$_path/departments/$departmentId/cities'),
    );
    return [
      for (final item in response.data ?? const [])
        CatalogCity.fromJson(item as Map<String, dynamic>),
    ];
  }
}
