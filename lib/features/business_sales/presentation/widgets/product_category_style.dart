import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/product.dart';

/// Ícono y colores de cada categoría de producto.
extension ProductCategoryStyle on ProductCategory {
  IconData get icon => switch (this) {
    ProductCategory.agua => Icons.water_drop_outlined,
    ProductCategory.bebida => Icons.local_drink_outlined,
    ProductCategory.hidratante => Icons.bolt_rounded,
    ProductCategory.cerveza => Icons.sports_bar_outlined,
    ProductCategory.snack => Icons.cookie_outlined,
    ProductCategory.comida => Icons.lunch_dining_outlined,
    ProductCategory.alquiler => Icons.sports_soccer_outlined,
    ProductCategory.otro => Icons.inventory_2_outlined,
  };

  Color get color => switch (this) {
    ProductCategory.agua => const Color(0xFF0284C7),
    ProductCategory.bebida => const Color(0xFFDC2626),
    ProductCategory.hidratante => const Color(0xFF7C3AED),
    ProductCategory.cerveza => const Color(0xFFD97706),
    ProductCategory.snack => const Color(0xFFB45309),
    ProductCategory.comida => const Color(0xFFEA580C),
    ProductCategory.alquiler => AppColors.emerald600,
    ProductCategory.otro => AppColors.slate500,
  };

  /// Fondo suave del ícono (funciona en claro y oscuro).
  Color get tint => color.withValues(alpha: 0.14);
}
