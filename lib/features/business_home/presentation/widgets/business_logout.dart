import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Pide confirmación y, si se acepta, cierra la sesión del administrador
/// con [signOut] (borra el token) y vuelve al login de negocio. El menú
/// lateral y "Mi cuenta" usan el mismo flujo.
Future<void> confirmBusinessLogout(
  BuildContext context, {
  required Future<void> Function() signOut,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('¿Cerrar sesión?', style: AppTypography.headlineSm),
      content: Text(
        'Tendrás que ingresar de nuevo para administrar tu negocio.',
        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.statusDue),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  await signOut();
  if (context.mounted) context.go(AppRoutes.businessLogin);
}
