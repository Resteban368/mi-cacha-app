import '../../../../core/usecase/usecase.dart';
import '../entities/cash_session.dart';
import '../repositories/cash_repository.dart';

class GetCashStatus implements UseCase<CashStatus, NoParams> {
  const GetCashStatus(this._repository);

  final CashRepository _repository;

  @override
  Future<CashStatus> call(NoParams _) => _repository.current();
}

typedef CashAmountParams = ({int amount, String? note});

class OpenCash implements UseCase<CashSession, CashAmountParams> {
  const OpenCash(this._repository);

  final CashRepository _repository;

  @override
  Future<CashSession> call(CashAmountParams params) {
    if (params.amount < 0) {
      throw ArgumentError('La base no puede ser negativa.');
    }
    return _repository.open(openingCash: params.amount, note: params.note);
  }
}

class CloseCash implements UseCase<CashSession, CashAmountParams> {
  const CloseCash(this._repository);

  final CashRepository _repository;

  @override
  Future<CashSession> call(CashAmountParams params) {
    if (params.amount < 0) {
      throw ArgumentError('El efectivo contado no puede ser negativo.');
    }
    return _repository.close(countedCash: params.amount, note: params.note);
  }
}

typedef CashExpenseParams = ({
  String supplierId,
  int amount,
  String method,
  String concept,
});

/// Pago a un proveedor en la caja abierta.
class AddCashExpense implements UseCase<CashExpense, CashExpenseParams> {
  const AddCashExpense(this._repository);

  final CashRepository _repository;

  @override
  Future<CashExpense> call(CashExpenseParams params) {
    if (params.amount <= 0) {
      throw ArgumentError('Escribe el valor del pago.');
    }
    if (params.concept.trim().length < 2) {
      throw ArgumentError('Escribe qué se pagó.');
    }
    return _repository.addExpense(
      supplierId: params.supplierId,
      amount: params.amount,
      method: params.method,
      concept: params.concept,
    );
  }
}

typedef VoidExpenseParams = ({String id, String reason});

class VoidCashExpense implements UseCase<CashExpense, VoidExpenseParams> {
  const VoidCashExpense(this._repository);

  final CashRepository _repository;

  @override
  Future<CashExpense> call(VoidExpenseParams params) {
    if (params.reason.trim().length < 3) {
      throw ArgumentError('Escribe el motivo.');
    }
    return _repository.voidExpense(params.id, params.reason);
  }
}

/// Proveedores: solo activos (para pagar) o todos (para administrarlos).
class GetSuppliers implements UseCase<List<Supplier>, bool> {
  const GetSuppliers(this._repository);

  final CashRepository _repository;

  @override
  Future<List<Supplier>> call(bool includeInactive) =>
      _repository.suppliers(includeInactive: includeInactive);
}

class SaveSupplier implements UseCase<Supplier, SupplierDraft> {
  const SaveSupplier(this._repository);

  final CashRepository _repository;

  @override
  Future<Supplier> call(SupplierDraft draft) {
    final name = draft.name.trim();
    if (name.length < 2) {
      throw ArgumentError('Escribe el nombre del proveedor.');
    }
    if (name.length > Supplier.maxName) {
      throw ArgumentError(
        'El nombre admite hasta ${Supplier.maxName} caracteres.',
      );
    }
    return _repository.saveSupplier(draft);
  }
}

typedef SupplierActiveParams = ({String id, bool isActive});

class SetSupplierActive implements UseCase<Supplier, SupplierActiveParams> {
  const SetSupplierActive(this._repository);

  final CashRepository _repository;

  @override
  Future<Supplier> call(SupplierActiveParams params) =>
      _repository.setSupplierActive(params.id, params.isActive);
}

typedef CashHistoryParams = ({int page, int pageSize});

class GetCashHistory
    implements
        UseCase<({List<CashSession> items, int total}), CashHistoryParams> {
  const GetCashHistory(this._repository);

  final CashRepository _repository;

  @override
  Future<({List<CashSession> items, int total})> call(
    CashHistoryParams params,
  ) => _repository.history(page: params.page, pageSize: params.pageSize);
}
