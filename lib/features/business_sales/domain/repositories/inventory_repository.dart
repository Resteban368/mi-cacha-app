import '../entities/inventory.dart';

abstract interface class InventoryRepository {
  Future<InventoryOverview> overview();

  /// Entrada de mercancía: suma al stock.
  Future<StockMovement> addEntry({
    required String productId,
    required int quantity,
    int? unitCost,
    String? supplierId,
    String? note,
  });

  /// Ajuste por conteo físico: deja el stock en [stock].
  Future<StockMovement> adjust({
    required String productId,
    required int stock,
    required String reason,
  });

  /// Activa o no el control de stock de un producto y su mínimo de alerta.
  Future<void> configure({
    required String productId,
    required bool trackStock,
    int? minStock,
  });

  /// Historial (de un producto o de todos), más reciente primero.
  Future<({List<StockMovement> items, int total})> movements({
    String? productId,
    required int page,
    required int pageSize,
  });
}
