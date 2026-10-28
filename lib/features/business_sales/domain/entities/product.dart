import 'package:equatable/equatable.dart';

/// Producto que el negocio vende por unidad (agua, bebida hidratante,
/// alquiler de petos…). No se borra: se desactiva.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.isActive = true,
  });

  static const maxName = 60;

  final String id;
  final String name;

  /// Precio por unidad en pesos colombianos (COP), sin decimales.
  final int price;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, price, isActive];
}
