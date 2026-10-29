import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../business_account/presentation/widgets/account_card.dart';
import '../bloc/business_notifications_cubit.dart';

/// Fila "Avisarme de nuevas reservas". No aparece si el navegador o el
/// servidor no soportan avisos.
class NotificationsSettingRow extends StatelessWidget {
  const NotificationsSettingRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessNotificationsCubit, BusinessNotificationsState>(
      builder: (context, state) {
        final status = state.status;
        if (status == BusinessNotificationsStatus.unsupported ||
            status == BusinessNotificationsStatus.unavailable) {
          return const SizedBox.shrink();
        }
        final loading = status == BusinessNotificationsStatus.loading;
        final denied = status == BusinessNotificationsStatus.denied;
        final enabled = status == BusinessNotificationsStatus.enabled;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              AccountIconBox(
                icon: Icons.notifications_active_outlined,
                background: AppColors.brandTealLight,
                foreground: AppColors.brandTeal,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notificaciones',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      _subtitle(status),
                      style: AppTypography.bodySm.copyWith(
                        color: denied
                            ? AppColors.statusDue
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (loading)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(
                  key: const Key('notifications-switch'),
                  value: enabled,
                  activeTrackColor: AppColors.brandTeal,
                  onChanged: denied
                      ? null
                      : (on) => context
                            .read<BusinessNotificationsCubit>()
                            .toggle(on: on),
                ),
            ],
          ),
        );
      },
    );
  }

  static String _subtitle(
    BusinessNotificationsStatus status,
  ) => switch (status) {
    BusinessNotificationsStatus.enabled =>
      'Activas: suenan con nuevas reservas y avisos de Mi Cancha',
    BusinessNotificationsStatus.denied =>
      'Bloqueaste las notificaciones; permítelas desde el candado de la barra de direcciones',
    BusinessNotificationsStatus.error =>
      'No pudimos cambiar el aviso. Intenta de nuevo.',
    _ => 'Nuevas reservas y avisos de Mi Cancha, aunque la app esté cerrada',
  };
}
