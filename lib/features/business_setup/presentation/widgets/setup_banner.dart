import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/setup_progress.dart';

/// Franja inferior del panel mientras falta la configuración inicial.
class SetupBanner extends StatelessWidget {
  const SetupBanner({super.key, required this.progress});

  final SetupProgress progress;

  /// Mensaje para quien toca una sección bloqueada del menú.
  static String lockedMessage(SetupStep step) => switch (step) {
    SetupStep.business =>
      'Primero completa los datos de tu negocio en Mi negocio.',
    _ => 'Primero registra una cancha lista para recibir reservas.',
  };

  @override
  Widget build(BuildContext context) {
    final (title, detail) = switch (progress.step) {
      SetupStep.business => (
        'Paso 1 de 2 · Completa tu negocio',
        'Falta: ${_join(progress.missing.map((r) => r.label).toList())}.',
      ),
      _ => (
        'Paso 2 de 2 · Registra tu primera cancha',
        'Debe quedar activa y con la foto principal. Después podrás usar '
            'todo el panel.',
      ),
    };
    final foreground = AppColors.brandTealDeep;

    return Material(
      color: AppColors.brandTealLight,
      child: SafeArea(
        top: false,
        child: Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Icon(Icons.checklist_rounded, size: 22, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodySm.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: AppTypography.bodySm.copyWith(color: foreground),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// «a, b y c».
  static String _join(List<String> items) => switch (items) {
    [] => '',
    [final only] => only,
    _ => '${items.sublist(0, items.length - 1).join(', ')} y ${items.last}',
  };
}
