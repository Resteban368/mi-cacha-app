import '../entities/new_sale.dart';
import '../entities/product.dart';
import '../entities/sale.dart';

abstract interface class SalesRepository {
  /// Activos, los más vendidos primero (para vender); con
  /// [includeInactive], todos por nombre (catálogo).
  Future<List<Product>> getProducts({bool includeInactive = false});

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

  /// Ventas registradas el [day] (hora local), más recientes primero.
  Future<List<Sale>> getSales(DateTime day);

  Future<Sale> createSale(NewSale sale);

  Future<Sale> voidSale(String id, String reason);
}
