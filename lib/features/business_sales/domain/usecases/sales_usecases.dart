import '../../../../core/usecase/usecase.dart';
import '../entities/new_sale.dart';
import '../entities/product.dart';
import '../entities/sale.dart';
import '../repositories/sales_repository.dart';

/// Productos del negocio: solo activos (para vender) o todos (catálogo).
class GetProducts implements UseCase<List<Product>, bool> {
  const GetProducts(this._repository);

  final SalesRepository _repository;

  @override
  Future<List<Product>> call(bool includeInactive) =>
      _repository.getProducts(includeInactive: includeInactive);
}

typedef ProductDraft = ({
  String? id,
  String name,
  ProductCategory category,
  int price,
});

/// Crea el producto o, con `id`, cambia su nombre y precio.
class SaveProduct implements UseCase<Product, ProductDraft> {
  const SaveProduct(this._repository);

  final SalesRepository _repository;

  @override
  Future<Product> call(ProductDraft draft) {
    final name = draft.name.trim();
    if (name.length < 2) throw ArgumentError('Escribe el nombre del producto.');
    if (name.length > Product.maxName) {
      throw ArgumentError(
        'El nombre admite hasta ${Product.maxName} caracteres.',
      );
    }
    if (draft.price < 0) {
      throw ArgumentError('El precio no puede ser negativo.');
    }
    return switch (draft.id) {
      final id? => _repository.updateProduct(
        id,
        name: name,
        category: draft.category,
        price: draft.price,
      ),
      null => _repository.createProduct(
        name: name,
        category: draft.category,
        price: draft.price,
      ),
    };
  }
}

typedef ProductActiveParams = ({String id, bool isActive});

class SetProductActive implements UseCase<Product, ProductActiveParams> {
  const SetProductActive(this._repository);

  final SalesRepository _repository;

  @override
  Future<Product> call(ProductActiveParams params) =>
      _repository.updateProduct(params.id, isActive: params.isActive);
}

class GetSales implements UseCase<List<Sale>, DateTime> {
  const GetSales(this._repository);

  final SalesRepository _repository;

  @override
  Future<List<Sale>> call(DateTime day) => _repository.getSales(day);
}

class CreateSale implements UseCase<Sale, NewSale> {
  const CreateSale(this._repository);

  final SalesRepository _repository;

  @override
  Future<Sale> call(NewSale sale) {
    final lines = sale.quantities.entries.where((e) => e.value > 0);
    if (lines.isEmpty) throw ArgumentError('Agrega al menos un producto.');
    if (lines.length > NewSale.maxItems) {
      throw ArgumentError(
        'Una venta admite hasta ${NewSale.maxItems} productos distintos.',
      );
    }
    if (lines.any((e) => e.value > NewSale.maxQuantity)) {
      throw ArgumentError(
        'Máximo ${NewSale.maxQuantity} unidades por producto.',
      );
    }
    if (sale.isWalkIn && sale.paymentMethod == null) {
      throw ArgumentError('Elige cómo te pagaron.');
    }
    return _repository.createSale(sale);
  }
}

typedef VoidSaleParams = ({String id, String reason});

class VoidSale implements UseCase<Sale, VoidSaleParams> {
  const VoidSale(this._repository);

  final SalesRepository _repository;

  @override
  Future<Sale> call(VoidSaleParams params) {
    final reason = params.reason.trim();
    if (reason.length < 3) throw ArgumentError('Escribe el motivo.');
    return _repository.voidSale(params.id, reason);
  }
}
