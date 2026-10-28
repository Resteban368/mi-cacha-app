import 'package:equatable/equatable.dart';

/// Lo cobrado con un método de pago durante un turno de caja.
class CashMethodTotal extends Equatable {
  const CashMethodTotal({
    required this.code,
    required this.name,
    this.count = 0,
    this.amount = 0,
  });

  /// `code` del catálogo de métodos de pago.
  final String code;
  final String name;
  final int count;
  final int amount;

  @override
  List<Object?> get props => [code, name, count, amount];
}

/// Proveedor del negocio (bebidas, hielo, aseo…). No se borra: se desactiva.
class Supplier extends Equatable {
  const Supplier({
    required this.id,
    required this.name,
    this.documentId,
    this.phone,
    this.notes,
    this.isActive = true,
  });

  static const maxName = 80;

  final String id;
  final String name;

  /// NIT o cédula.
  final String? documentId;
  final String? phone;
  final String? notes;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, documentId, phone, notes, isActive];
}

/// Pago a un proveedor durante un turno de caja. En efectivo se descuenta
/// del efectivo esperado.
class CashExpense extends Equatable {
  const CashExpense({
    required this.id,
    required this.supplierName,
    required this.amount,
    required this.method,
    required this.concept,
    required this.createdAt,
    this.supplierId,
    this.methodName,
    this.createdByName,
    this.voidedAt,
    this.voidReason,
  });

  final String id;
  final String? supplierId;
  final String supplierName;
  final int amount;

  /// `code` del catálogo de métodos de pago.
  final String method;
  final String? methodName;
  final String concept;
  final DateTime createdAt;
  final String? createdByName;
  final DateTime? voidedAt;
  final String? voidReason;

  bool get isVoided => voidedAt != null;

  @override
  List<Object?> get props => [
    id,
    supplierId,
    supplierName,
    amount,
    method,
    methodName,
    concept,
    createdAt,
    createdByName,
    voidedAt,
    voidReason,
  ];
}

/// Turno de caja: se abre con una base de efectivo y se cierra contando el
/// efectivo real (arqueo).
class CashSession extends Equatable {
  const CashSession({
    required this.id,
    required this.openingCash,
    required this.openedAt,
    required this.expectedCash,
    this.openingNote,
    this.openedByName,
    this.closedAt,
    this.closedByName,
    this.closingNote,
    this.countedCash,
    this.difference,
    this.methods = const [],
    this.collected = 0,
    this.expenses = const [],
    this.expensesTotal = 0,
    this.cashExpensesTotal = 0,
  });

  final String id;
  final int openingCash;
  final String? openingNote;
  final DateTime openedAt;
  final String? openedByName;
  final DateTime? closedAt;
  final String? closedByName;
  final String? closingNote;

  /// Base + cobros en efectivo − pagos a proveedores en efectivo (hasta
  /// ahora si sigue abierta).
  final int expectedCash;

  /// `null` mientras la caja está abierta.
  final int? countedCash;

  /// Contado − esperado: positivo = sobrante, negativo = faltante.
  final int? difference;

  /// Cobros del turno por método, de mayor a menor.
  final List<CashMethodTotal> methods;

  /// Suma de todos los métodos.
  final int collected;

  /// Pagos a proveedores del turno (también los anulados), más recientes
  /// primero.
  final List<CashExpense> expenses;

  /// Pagos sin anular de cualquier método y, de ellos, los en efectivo.
  final int expensesTotal;
  final int cashExpensesTotal;

  bool get isOpen => closedAt == null;

  @override
  List<Object?> get props => [
    id,
    openingCash,
    openingNote,
    openedAt,
    openedByName,
    closedAt,
    closedByName,
    closingNote,
    expectedCash,
    countedCash,
    difference,
    methods,
    collected,
    expenses,
    expensesTotal,
    cashExpensesTotal,
  ];
}

/// Estado de la caja: la abierta (si hay) y el último cierre.
class CashStatus extends Equatable {
  const CashStatus({this.session, this.lastClosed});

  final CashSession? session;
  final CashSession? lastClosed;

  @override
  List<Object?> get props => [session, lastClosed];
}
