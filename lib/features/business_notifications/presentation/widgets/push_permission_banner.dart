import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/business_notifications_cubit.dart';

/// Arriba de la bandeja: si los avisos de este navegador no están activos,
/// explica por qué y permite activarlos (el permiso se pide en el toque).
class PushPermissionBanner extends StatelessWidget {
  const PushPermissionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessNotificationsCubit, BusinessNotificationsState>(
      builder: (context, state) {
        final cubit = context.read<BusinessNotificationsCubit>();
        final (icon, color, text, action, onAction) = switch (state.status) {
          BusinessNotificationsStatus.disabled => (
            Icons.notifications_off_outlined,
            AppColors.brandTeal,
            'Activa las notificaciones para que suenen y te avisen de nuevas '
                'reservas aunque no estés mirando la app.',
            'Activar',
            () => cubit.toggle(on: true),
          ),
          BusinessNotificationsStatus.denied => (
            Icons.block_rounded,
            AppColors.statusDue,
            'Las notificaciones están bloqueadas en este navegador. Toca el '
                'candado (o el ícono de ajustes) junto a la dirección de la '
                'página, cambia "Notificaciones" a "Permitir" y recarga.',
            'Ya las permití',
            cubit.load,
          ),
          BusinessNotificationsStatus.unsupported => (
            Icons.info_outline_rounded,
            AppColors.slate600,
            'Este navegador no permite notificaciones. En iPhone, abre Mi '
                'Cancha desde Safari, toca Compartir → "Agregar a inicio" y '
                'ábrela desde ese ícono.',
            null,
            null,
          ),
          BusinessNotificationsStatus.unavailable ||
          BusinessNotificationsStatus.error => (
            Icons.error_outline_rounded,
            AppColors.amber500,
            'No pudimos activar las notificaciones. Revisa tu conexión e '
                'intenta de nuevo.',
            'Reintentar',
            () => cubit.toggle(on: true),
          ),
          BusinessNotificationsStatus.loading ||
          BusinessNotificationsStatus.enabled => (null, null, null, null, null),
        };
        if (icon == null || color == null || text == null) {
          return const SizedBox.shrink();
        }
        return Container(
          key: Key('push-banner-${state.status.name}'),
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate700,
                      ),
                    ),
                    if (action != null && onAction != null) ...[
                      const SizedBox(height: 8),
                      FilledButton(
                        key: const Key('push-banner-action'),
                        onPressed: onAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: color,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(action),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
