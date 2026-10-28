import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Aviso cuando el negocio no tiene activo el módulo de Ventas (o el de
/// Inventario, con [SalesModuleLocked.inventory]).
class SalesModuleLocked extends StatelessWidget {
  const SalesModuleLocked({super.key})
    : title = 'El módulo de Ventas no está activo',
      message =
          'Con él registras productos, consumos de las reservas, '
          'ventas sueltas y el cierre de caja. Pídele a Mi Cancha que '
          'lo active para tu negocio.';

  const SalesModuleLocked.inventory({super.key})
    : title = 'El módulo de Inventario no está activo',
      message =
          'Con él llevas el stock de tus productos: se descuenta al '
          'vender, registras entradas de mercancía y recibes alertas de '
          'stock bajo. Pídele a Mi Cancha que lo active para tu negocio.';

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('sales-module-locked'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.brandTealLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 30,
                  color: AppColors.brandTealDeep,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: AppColors.slate600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
