import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'sales_api_data_source.dart';

/// Inventario del negocio en la API (`/business/inventory`).
class InventoryApiDataSource implements InventoryRepository {
  const InventoryApiDataSource(this._dio);

  final Dio _dio;

  static const _path = '/business/inventory';

  @override
  Future<InventoryOverview> overview() async {
    final response = await apiCall(() => _dio.get<Map<String, dynamic>>(_path));
    final json = response.data ?? const {};
    return InventoryOverview(
      items: [
        for (final item in (json['items'] as List<dynamic>? ?? const []))
          SalesApiDataSource.productFromJson(item as Map<String, dynamic>),
      ],
      tracked: (json['tracked'] as num?)?.toInt() ?? 0,
      low: (json['low'] as num?)?.toInt() ?? 0,
      out: (json['out'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<StockMovement> addEntry({
    required String productId,
    required int quantity,
    int? unitCost,
    String? supplierId,
    String? note,
  }) async {
    final text = note?.trim();
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(
        '$_path/entries',
        data: {
          'productId': productId,
          'quantity': quantity,
          'unitCost': ?unitCost,
          'supplierId': ?supplierId,
          if (text != null && text.isNotEmpty) 'note': text,
        },
      ),
    );
    return movementFromJson(response.data!);
  }

  @override
  Future<StockMovement> adjust({
    required String productId,
    required int stock,
    required String reason,
  }) async {
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(
        '$_path/adjustments',
        data: {'productId': productId, 'stock': stock, 'reason': reason.trim()},
      ),
    );
    return movementFromJson(response.data!);
  }

  @override
  Future<void> configure({
    required String productId,
    required bool trackStock,
    int? minStock,
  }) async {
    await apiCall(
      () => _dio.patch<Map<String, dynamic>>(
        '/business/products/$productId',
        data: {'trackStock': trackStock, 'minStock': minStock},
      ),
    );
  }

  @override
  Future<({List<StockMovement> items, int total})> movements({
    String? productId,
    required int page,
    required int pageSize,
  }) async {
    final response = await apiCall(
      () => _dio.get<Map<String, dynamic>>(
        '$_path/movements',
        queryParameters: {
          'productId': ?productId,
          'page': page,
          'pageSize': pageSize,
        },
      ),
    );
    final json = response.data ?? const {};
    return (
      items: [
        for (final item in (json['items'] as List<dynamic>? ?? const []))
          movementFromJson(item as Map<String, dynamic>),
      ],
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  static StockMovement movementFromJson(Map<String, dynamic> json) =>
      StockMovement(
        id: json['id'] as String,
        productId: json['productId'] as String? ?? '',
        productName: json['productName'] as String? ?? '',
        type: StockMovementType.fromApi(json['type'] as String?),
        quantity: (json['quantity'] as num? ?? 0).toInt(),
        stockAfter: (json['stockAfter'] as num? ?? 0).toInt(),
        unitCost: (json['unitCost'] as num?)?.round(),
        supplierName: json['supplierName'] as String?,
        note: json['note'] as String?,
        createdByName: json['createdByName'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );
}
