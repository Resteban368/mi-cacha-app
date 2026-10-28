import 'package:equatable/equatable.dart';

/// Categoría de un producto (fija en la plataforma): define su ícono.
enum ProductCategory {
  agua('AGUA', 'Agua'),
  bebida('BEBIDA', 'Bebida'),
  hidratante('HIDRATANTE', 'Hidratante'),
  cerveza('CERVEZA', 'Cerveza'),
  snack('SNACK', 'Snack'),
  comida('COMIDA', 'Comida'),
  alquiler('ALQUILER', 'Alquiler'),
  otro('OTRO', 'Otro');

  const ProductCategory(this.apiCode, this.label);

  /// Valor exacto que envía y recibe la API.
  final String apiCode;
  final String label;

  static ProductCategory fromApi(String? code) =>
      values.firstWhere((c) => c.apiCode == code, orElse: () => otro);

  static const _hints = {
    hidratante: ['gatorade', 'powerade', 'hidratante', 'electrolit', 'suero'],
    agua: ['agua', 'brisa', 'cristal'],
    cerveza: [
      'cerveza',
      'poker',
      'aguila',
      'águila',
      'club colombia',
      'corona',
    ],
    bebida: [
      'gaseosa',
      'coca',
      'pepsi',
      'jugo',
      'té',
      'pony',
      'postobon',
      'soda',
    ],
    snack: ['papas', 'mani', 'maní', 'galleta', 'chocolate', 'snack', 'dulce'],
    comida: ['empanada', 'perro', 'hamburguesa', 'pizza', 'arepa', 'sandwich'],
    alquiler: [
      'alquiler',
      'peto',
      'balón',
      'balon',
      'raqueta',
      'pelota',
      'guayo',
    ],
  };

  /// Categoría probable según el nombre ("Gatorade 500 ml" → hidratante).
  static ProductCategory guess(String name) {
    final text = name.toLowerCase();
    for (final MapEntry(:key, :value) in _hints.entries) {
      if (value.any(text.contains)) return key;
    }
    return otro;
  }
}

/// Producto que el negocio vende por unidad (agua, bebida hidratante,
/// alquiler de petos…). No se borra: se desactiva.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.category = ProductCategory.otro,
    this.isActive = true,
    this.sold = 0,
    this.trackStock = false,
    this.stock = 0,
    this.minStock,
  });

  static const maxName = 60;

  final String id;
  final String name;
  final ProductCategory category;

  /// Precio por unidad en pesos colombianos (COP), sin decimales.
  final int price;
  final bool isActive;

  /// Unidades vendidas en los últimos 30 días.
  final int sold;

  /// Inventario: si se controlan sus existencias, cuántas hay y el mínimo
  /// para la alerta (`null` = sin alerta).
  final bool trackStock;
  final int stock;
  final int? minStock;

  bool get isOut => trackStock && stock <= 0;

  /// Sin unidades o en el mínimo.
  bool get isLow =>
      trackStock && (stock <= 0 || (minStock != null && stock <= minStock!));

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    price,
    isActive,
    sold,
    trackStock,
    stock,
    minStock,
  ];
}
