import '../../domain/entities/new_sale.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sales_repository.dart';
import '../datasources/sales_data_source.dart';

class SalesRepositoryImpl implements SalesRepository {
  const SalesRepositoryImpl(this._dataSource);

  final SalesDataSource _dataSource;

  @override
  Future<List<Product>> getProducts({bool includeInactive = false}) =>
      _dataSource.getProducts(includeInactive: includeInactive);

  @override
  Future<Product> createProduct({required String name, required int price}) =>
      _dataSource.createProduct(name: name, price: price);

  @override
  Future<Product> updateProduct(
    String id, {
    String? name,
    int? price,
    bool? isActive,
  }) => _dataSource.updateProduct(
    id,
    name: name,
    price: price,
    isActive: isActive,
  );

  @override
  Future<List<Sale>> getSales(DateTime day) => _dataSource.getSales(day);

  @override
  Future<Sale> createSale(NewSale sale) => _dataSource.createSale(sale);

  @override
  Future<Sale> voidSale(String id, String reason) =>
      _dataSource.voidSale(id, reason);
}
