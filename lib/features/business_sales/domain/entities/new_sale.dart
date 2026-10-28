import 'package:equatable/equatable.dart';

/// Venta por registrar: consumo de [reservationId] o, sin reserva, venta
/// suelta pagada con [paymentMethod].
class NewSale extends Equatable {
  const NewSale({
    required this.quantities,
    this.reservationId,
    this.paymentMethod,
    this.reference,
    this.customerName,
    this.note,
  });

  /// Productos por línea y unidades máximas de cada uno (límites de la API).
  static const maxItems = 30;
  static const maxQuantity = 999;

  /// Unidades por id de producto.
  final Map<String, int> quantities;
  final String? reservationId;

  /// `code` del catálogo de métodos de pago (solo en una venta suelta).
  final String? paymentMethod;
  final String? reference;
  final String? customerName;

  /// Nota para la venta (p. ej. "sin hielo"); hasta [maxNote] caracteres.
  final String? note;

  static const maxNote = 300;

  bool get isWalkIn => reservationId == null;

  @override
  List<Object?> get props => [
    quantities,
    reservationId,
    paymentMethod,
    reference,
    customerName,
    note,
  ];
}
