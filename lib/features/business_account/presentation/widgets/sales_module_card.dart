import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/business_account.dart';
import 'account_card.dart';

/// Detalle del módulo de Ventas e inventario, debajo del plan (solo si está
/// activo).
class SalesModuleCard extends StatelessWidget {
  const SalesModuleCard({super.key, required this.module, this.onOpen});

  final SalesModule module;

  /// Ir a la sección Ventas.
  final VoidCallback? onOpen;

  static const _features = [
    (Icons.inventory_2_outlined, 'Catálogo de productos con categorías'),
    (Icons.add_shopping_cart_rounded, 'Consumos cargados a las reservas'),
    (Icons.shopping_bag_outlined, 'Ventas sueltas de mostrador'),
    (Icons.fact_check_outlined, 'Caja del día: apertura, arqueo y cierre'),
    (Icons.insights_outlined, 'Ventas y más vendidos en el dashboard'),
    (Icons.inventory_rounded, 'Inventario: stock por producto y entradas'),
    (Icons.notification_important_outlined, 'Alertas de stock bajo y agotados'),
  ];

  @override
  Widget build(BuildContext context) {
    return AccountCard(
      key: const Key('sales-module-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AccountIconBox(icon: Icons.point_of_sale_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Módulo de Ventas e inventario',
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
          for (final (icon, text) in _features)
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
                key: const Key('open-sales'),
                onPressed: onOpen,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Ir a Ventas'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
