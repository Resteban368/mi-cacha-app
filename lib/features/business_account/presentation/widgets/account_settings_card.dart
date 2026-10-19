import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'account_card.dart';

/// "Configuración y seguridad": contraseña, soporte y cierre de sesión.
class AccountSettingsCard extends StatelessWidget {
  const AccountSettingsCard({
    super.key,
    required this.onChangePassword,
    required this.onSupport,
    required this.onLogout,
    this.notifications,
  });

  final VoidCallback onChangePassword;
  final VoidCallback onSupport;
  final VoidCallback onLogout;

  /// Fila de avisos push (solo web). Se omite si no hay.
  final Widget? notifications;

  @override
  Widget build(BuildContext context) {
    return AccountCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 20, color: AppColors.brandTeal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Configuración y seguridad',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.lock_reset,
            title: 'Cambiar contraseña',
            subtitle: 'Seguridad de acceso y doble factor',
            onTap: onChangePassword,
          ),
          _SettingsTile(
            icon: Icons.forum_outlined,
            iconBackground: AppColors.brandTealLight,
            title: 'Soporte por WhatsApp',
            badge: '< 10 min',
            subtitle: 'Asistencia directa del equipo técnico',
            onTap: onSupport,
          ),
          ?notifications,
          _SettingsTile(
            icon: Icons.logout,
            iconBackground: AppColors.errorContainer,
            color: AppColors.error,
            title: 'Cerrar sesión',
            subtitle: 'Salir del panel en este dispositivo',
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconBackground = AppColors.surfaceContainerLow,
    this.color,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconBackground;

  /// Color de acciones destructivas (ícono, título y flecha).
  final Color? color;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              AccountIconBox(
                icon: icon,
                background: iconBackground,
                foreground: color ?? AppColors.brandTeal,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: AppTypography.labelMd.copyWith(
                            color: color ?? AppColors.onSurface,
                            fontWeight: color == null ? null : FontWeight.w700,
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.whatsapp.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge,
                              style: AppTypography.labelSm.copyWith(
                                fontSize: 10,
                                color: AppColors.brandTeal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color:
                    color?.withValues(alpha: 0.6) ?? AppColors.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
