import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/new_sale.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/sale.dart';
import 'sales_data_source.dart';

/// Productos (`/business/products`) y ventas (`/business/sales`) del negocio.
class SalesApiDataSource implements SalesDataSource {
  const SalesApiDataSource(this._dio);

  final Dio _dio;

  static const _products = '/business/products';
  static const _sales = '/business/sales';

  @override
  Future<List<Product>> getProducts({required bool includeInactive}) async {
    final response = await apiCall(
      () => _dio.get<List<dynamic>>(
        _products,
        // Para vender: los más vendidos primero; el catálogo, por nombre.
        queryParameters: includeInactive
            ? {'includeInactive': true}
            : {'sort': 'popular'},
      ),
    );
    return [
      for (final item in response.data ?? const [])
        productFromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<Product> createProduct({
    required String name,
    required ProductCategory category,
    required int price,
  }) async {
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(
        _products,
        data: {'name': name, 'category': category.apiCode, 'price': price},
      ),
    );
    return productFromJson(response.data!);
  }

  @override
  Future<Product> updateProduct(
    String id, {
    String? name,
    ProductCategory? category,
    int? price,
    bool? isActive,
  }) async {
    final response = await apiCall(
      () => _dio.patch<Map<String, dynamic>>(
        '$_products/$id',
        data: {
          'name': ?name,
          'category': ?category?.apiCode,
          'price': ?price,
          'isActive': ?isActive,
        },
      ),
    );
    return productFromJson(response.data!);
  }

  @override
  Future<List<Sale>> getSales(DateTime day) async {
    final response = await apiCall(
      () => _dio.get<List<dynamic>>(
        _sales,
        queryParameters: {'date': _dayParam(day)},
      ),
    );
    return [
      for (final item in response.data ?? const [])
        saleFromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<Sale> createSale(NewSale sale) async {
    final customer = sale.customerName?.trim();
    final reference = sale.reference?.trim();
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(
        _sales,
        data: {
          'reservationId': ?sale.reservationId,
          'items': [
            for (final MapEntry(:key, :value) in sale.quantities.entries)
              if (value > 0) {'productId': key, 'quantity': value},
          ],
          if (sale.paymentMethod case final method?)
            'payment': {
              'method': method,
              if (reference != null && reference.isNotEmpty)
                'reference': reference,
            },
          if (customer != null && customer.isNotEmpty) 'customerName': customer,
        },
      ),
    );
    return saleFromJson(response.data!);
  }

  @override
  Future<Sale> voidSale(String id, String reason) async {
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(
        '$_sales/$id/void',
        data: {'reason': reason},
      ),
    );
    return saleFromJson(response.data!);
  }

  static String _dayParam(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static int _money(Object? value) => (value as num? ?? 0).round();

  static Product productFromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    category: ProductCategory.fromApi(json['category'] as String?),
    price: _money(json['price']),
    isActive: json['isActive'] as bool? ?? true,
    sold: (json['sold'] as num? ?? 0).toInt(),
  );

  /// También lo usan las reservas para sus consumos.
  static Sale saleFromJson(Map<String, dynamic> json) => Sale(
    id: json['id'] as String,
    reservationId: json['reservationId'] as String?,
    customerName: json['customerName'] as String?,
    total: _money(json['total']),
    note: json['note'] as String?,
    status: SaleStatus.fromApi(json['status'] as String?),
    voidReason: json['voidReason'] as String?,
    voidedAt: switch (json['voidedAt']) {
      final String at => DateTime.parse(at).toLocal(),
      _ => null,
    },
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    items: [
      for (final item in (json['items'] as List<dynamic>? ?? const []))
        if (item case final Map<String, dynamic> line)
          SaleItem(
            productId: line['productId'] as String?,
            productName: line['productName'] as String? ?? '',
            unitPrice: _money(line['unitPrice']),
            quantity: (line['quantity'] as num? ?? 0).toInt(),
            subtotal: _money(line['subtotal']),
          ),
    ],
    paymentMethod: json['paymentMethod'] as String?,
  );
}
