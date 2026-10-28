import '../entities/cash_session.dart';

/// Datos de un proveedor nuevo (sin `id`) o editado.
typedef SupplierDraft = ({
  String? id,
  String name,
  String? documentId,
  String? phone,
  String? notes,
});

abstract interface class CashRepository {
  Future<CashStatus> current();

  Future<CashSession> open({required int openingCash, String? note});

  Future<CashSession> close({required int countedCash, String? note});

  Future<CashExpense> addExpense({
    required String supplierId,
    required int amount,
    required String method,
    required String concept,
  });

  Future<CashExpense> voidExpense(String id, String reason);

  Future<CashMovement> addMovement({
    required CashMovementType type,
    required int amount,
    required String reason,
  });

  Future<CashMovement> voidMovement(String id, String reason);

  /// Activos por nombre; con [includeInactive] también los desactivados.
  Future<List<Supplier>> suppliers({bool includeInactive = false});

  Future<Supplier> saveSupplier(SupplierDraft draft);

  Future<Supplier> setSupplierActive(String id, bool isActive);

  /// Cierres anteriores, más recientes primero.
  Future<({List<CashSession> items, int total})> history({
    required int page,
    required int pageSize,
  });
}
