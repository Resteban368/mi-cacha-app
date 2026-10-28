import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/business_account.dart';
import 'account_card.dart';

/// Detalle de un módulo activo (Ventas o Inventario), debajo del plan.
class SalesModuleCard extends StatelessWidget {
  const SalesModuleCard({super.key, required this.module, this.onOpen})
    : title = 'Módulo de Ventas',
      icon = Icons.point_of_sale_rounded,
      features = _salesFeatures,
      openLabel = 'Ir a Ventas',
      _id = 'sales';

  const SalesModuleCard.inventory({
    super.key,
    required this.module,
    this.onOpen,
  }) : title = 'Módulo de Inventario',
       icon = Icons.inventory_rounded,
       features = _inventoryFeatures,
       openLabel = 'Ir a Inventario',
       _id = 'inventory';

  final SalesModule module;
  final String title;
  final IconData icon;
  final List<(IconData, String)> features;
  final String openLabel;
  final String _id;

  /// Ir a la sección del módulo.
  final VoidCallback? onOpen;

  static const _inventoryFeatures = [
    (Icons.inventory_2_outlined, 'Stock por producto, se descuenta al vender'),
    (
      Icons.move_to_inbox_outlined,
      'Entradas de mercancía con costo y proveedor',
    ),
    (Icons.fact_check_outlined, 'Ajustes por conteo físico con motivo'),
    (Icons.notification_important_outlined, 'Alertas de stock bajo y agotados'),
  ];

  static const _salesFeatures = [
    (Icons.inventory_2_outlined, 'Catálogo de productos con categorías'),
    (Icons.add_shopping_cart_rounded, 'Consumos cargados a las reservas'),
    (Icons.shopping_bag_outlined, 'Ventas sueltas de mostrador'),
    (Icons.fact_check_outlined, 'Caja del día: apertura, arqueo y cierre'),
    (Icons.insights_outlined, 'Ventas y más vendidos en el dashboard'),
  ];

  @override
  Widget build(BuildContext context) {
    return AccountCard(
      key: Key('$_id-module-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AccountIconBox(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLg.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (module.enabledAt case final since?)
                      Text(
                        'Activo desde el ${AppFormatters.mediumDate(since)}',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.slate500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'ACTIVO',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.emerald800,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final (icon, text) in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.brandTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (onOpen != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: Key('open-$_id'),
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(openLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
