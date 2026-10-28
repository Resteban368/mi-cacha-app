import 'package:equatable/equatable.dart';

import 'product.dart';

/// Existencias de los productos activos y sus alertas.
class InventoryOverview extends Equatable {
  const InventoryOverview({
    this.items = const [],
    this.tracked = 0,
    this.low = 0,
    this.out = 0,
  });

  /// Productos activos (con y sin control de stock), por nombre.
  final List<Product> items;

  /// Con control de stock, con stock bajo (aún con unidades) y agotados.
  final int tracked;
  final int low;
  final int out;

  /// Productos que piden atención: agotados más los de stock bajo.
  int get alerts => low + out;

  @override
  List<Object?> get props => [items, tracked, low, out];
}

/// Por qué cambió el stock (fijo en la plataforma).
enum StockMovementType {
  entrada('ENTRADA', 'Entrada'),
  ajuste('AJUSTE', 'Ajuste'),
  venta('VENTA', 'Venta'),
  anulacion('ANULACION', 'Anulación');

  const StockMovementType(this.apiCode, this.label);

  final String apiCode;
  final String label;

  static StockMovementType fromApi(String? code) =>
      values.firstWhere((t) => t.apiCode == code, orElse: () => ajuste);
}

/// Un cambio de stock de un producto.
class StockMovement extends Equatable {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.stockAfter,
    required this.createdAt,
    this.unitCost,
    this.supplierName,
    this.note,
    this.createdByName,
  });

  final String id;
  final String productId;
  final String productName;
  final StockMovementType type;

  /// Unidades que entran (+) o salen (−).
  final int quantity;
  final int stockAfter;
  final int? unitCost;
  final String? supplierName;
  final String? note;
  final String? createdByName;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    type,
    quantity,
    stockAfter,
    unitCost,
    supplierName,
    note,
    createdByName,
    createdAt,
  ];
}
