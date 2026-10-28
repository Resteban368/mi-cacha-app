import '../entities/new_sale.dart';
import '../entities/product.dart';
import '../entities/sale.dart';

abstract interface class SalesRepository {
  /// Productos por nombre; con [includeInactive] también los desactivados.
  Future<List<Product>> getProducts({bool includeInactive = false});

  Future<Product> createProduct({required String name, required int price});

  Future<Product> updateProduct(
    String id, {
    String? name,
    int? price,
    bool? isActive,
  });

  /// Ventas registradas el [day] (hora local), más recientes primero.
  Future<List<Sale>> getSales(DateTime day);

  Future<Sale> createSale(NewSale sale);

  Future<Sale> voidSale(String id, String reason);
}
