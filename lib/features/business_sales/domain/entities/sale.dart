import 'package:equatable/equatable.dart';

/// Estado de una venta (fijo en la plataforma).
enum SaleStatus {
  active('ACTIVE'),

  /// Anulada por el negocio: ya no suma ni se cobra, pero queda registrada.
  voided('VOIDED');

  const SaleStatus(this.apiCode);

  /// Valor exacto que envía y recibe la API.
  final String apiCode;

  static SaleStatus fromApi(String? code) =>
      values.firstWhere((s) => s.apiCode == code, orElse: () => active);
}

/// Línea de una venta, con el nombre y el precio del momento de vender.
class SaleItem extends Equatable {
  const SaleItem({
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.productId,
  });

  /// `null` si el producto ya no existe.
  final String? productId;
  final String productName;
  final int unitPrice;
  final int quantity;
  final int subtotal;

  @override
  List<Object?> get props => [
    productId,
    productName,
    unitPrice,
    quantity,
    subtotal,
  ];
}

/// Venta de productos: consumo cargado a una reserva (se cobra con su saldo)
/// o venta suelta, que se paga en el momento.
class Sale extends Equatable {
  const Sale({
    required this.id,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.items,
    this.reservationId,
    this.customerName,
    this.note,
    this.voidReason,
    this.voidedAt,
    this.paymentMethod,
    this.courtName,
    this.reservationStart,
    this.reservationPaid = false,
  });

  final String id;

  /// `null` en una venta suelta.
  final String? reservationId;
  final String? customerName;
  final int total;
  final String? note;
  final SaleStatus status;
  final String? voidReason;
  final DateTime? voidedAt;
  final DateTime createdAt;
  final List<SaleItem> items;

  /// `code` del método con que se pagó (venta suelta o consumo cobrado ya);
  /// `null` si el consumo se cargó al saldo de la reserva.
  final String? paymentMethod;

  /// Cancha e inicio de la reserva de un consumo.
  final String? courtName;
  final DateTime? reservationStart;

  /// Consumo cargado al saldo cuya reserva ya se pagó por completo.
  final bool reservationPaid;

  bool get isVoided => status == SaleStatus.voided;
  bool get isWalkIn => reservationId == null;

  /// Ya se cobró: venta suelta, consumo pagado en el momento o consumo
  /// cuya reserva ya quedó pagada.
  bool get isPaid => paymentMethod != null || reservationPaid;

  /// `12 × Gatorade · 6 × Agua`
  String get itemsLabel =>
      items.map((i) => '${i.quantity} × ${i.productName}').join(' · ');

  @override
  List<Object?> get props => [
    id,
    reservationId,
    customerName,
    total,
    note,
    status,
    voidReason,
    voidedAt,
    createdAt,
    items,
    paymentMethod,
    courtName,
    reservationStart,
    reservationPaid,
  ];
}
