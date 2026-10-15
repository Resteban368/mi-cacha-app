import 'package:dio/dio.dart';

import '../../../network/api_exception.dart';
import '../../domain/entities/app_catalogs.dart';
import 'catalogs_data_source.dart';

/// Catálogos en la API (`GET /catalogs`).
class CatalogsApiDataSource implements CatalogsDataSource {
  const CatalogsApiDataSource(this._dio);

  final Dio _dio;

  static const _path = '/catalogs';

  @override
  Future<AppCatalogs> getCatalogs() async {
    final response = await apiCall(() => _dio.get<Map<String, dynamic>>(_path));
    return AppCatalogs.fromJson(response.data!);
  }
}
