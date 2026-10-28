import '../../domain/entities/new_sale.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/sale.dart';

abstract interface class SalesDataSource {
  Future<List<Product>> getProducts({required bool includeInactive});

  Future<Product> createProduct({
    required String name,
    required ProductCategory category,
    required int price,
  });

  Future<Product> updateProduct(
    String id, {
    String? name,
    ProductCategory? category,
    int? price,
    bool? isActive,
  });

  Future<List<Sale>> getSales(DateTime day);

  Future<Sale> createSale(NewSale sale);

  Future<Sale> voidSale(String id, String reason);
}
