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
  });

  final String id;
  final int openingCash;
  final String? openingNote;
  final DateTime openedAt;
  final String? openedByName;
  final DateTime? closedAt;
  final String? closedByName;
  final String? closingNote;

  /// Base + cobros en efectivo del turno (hasta ahora si sigue abierta).
  final int expectedCash;

  /// `null` mientras la caja está abierta.
  final int? countedCash;

  /// Contado − esperado: positivo = sobrante, negativo = faltante.
  final int? difference;

  /// Cobros del turno por método, de mayor a menor.
  final List<CashMethodTotal> methods;

  /// Suma de todos los métodos.
  final int collected;

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
