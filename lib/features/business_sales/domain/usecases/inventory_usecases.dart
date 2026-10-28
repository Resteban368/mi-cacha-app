import '../../../../core/usecase/usecase.dart';
import '../entities/inventory.dart';
import '../repositories/inventory_repository.dart';

class GetInventory implements UseCase<InventoryOverview, NoParams> {
  const GetInventory(this._repository);

  final InventoryRepository _repository;

  @override
  Future<InventoryOverview> call(NoParams _) => _repository.overview();
}

typedef StockEntryParams = ({
  String productId,
  int quantity,
  int? unitCost,
  String? supplierId,
  String? note,
});

/// Entrada de mercancía (compra).
class AddStockEntry implements UseCase<StockMovement, StockEntryParams> {
  const AddStockEntry(this._repository);

  final InventoryRepository _repository;

  static const maxUnits = 100000;

  @override
  Future<StockMovement> call(StockEntryParams params) {
    if (params.quantity <= 0) {
      throw ArgumentError('Escribe cuántas unidades entran.');
    }
    if (params.quantity > maxUnits) {
      throw ArgumentError('Máximo $maxUnits unidades por entrada.');
    }
    return _repository.addEntry(
      productId: params.productId,
      quantity: params.quantity,
      unitCost: params.unitCost,
      supplierId: params.supplierId,
      note: params.note,
    );
  }
}

typedef StockAdjustParams = ({String productId, int stock, String reason});

/// Ajuste por conteo físico.
class AdjustStock implements UseCase<StockMovement, StockAdjustParams> {
  const AdjustStock(this._repository);

  final InventoryRepository _repository;

  @override
  Future<StockMovement> call(StockAdjustParams params) {
    if (params.stock < 0) {
      throw ArgumentError('El stock no puede ser negativo.');
    }
    if (params.reason.trim().length < 2) {
      throw ArgumentError('Escribe el motivo del ajuste.');
    }
    return _repository.adjust(
      productId: params.productId,
      stock: params.stock,
      reason: params.reason,
    );
  }
}

typedef StockConfigParams = ({
  String productId,
  bool trackStock,
  int? minStock,
});

/// Control de stock de un producto y su alerta de stock bajo.
class ConfigureStock implements UseCase<void, StockConfigParams> {
  const ConfigureStock(this._repository);

  final InventoryRepository _repository;

  @override
  Future<void> call(StockConfigParams params) {
    if ((params.minStock ?? 0) < 0) {
      throw ArgumentError('El mínimo no puede ser negativo.');
    }
    return _repository.configure(
      productId: params.productId,
      trackStock: params.trackStock,
      minStock: params.minStock,
    );
  }
}

typedef StockMovementsParams = ({String? productId, int page, int pageSize});

class GetStockMovements
    implements
        UseCase<
          ({List<StockMovement> items, int total}),
          StockMovementsParams
        > {
  const GetStockMovements(this._repository);

  final InventoryRepository _repository;

  @override
  Future<({List<StockMovement> items, int total})> call(
    StockMovementsParams params,
  ) => _repository.movements(
    productId: params.productId,
    page: params.page,
    pageSize: params.pageSize,
  );
}
