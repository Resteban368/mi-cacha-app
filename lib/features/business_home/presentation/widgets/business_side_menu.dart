import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../navigation/business_section.dart';
import '../../../../core/widgets/app_logo_icon.dart';

/// Contenido del menú lateral: cabecera de marca, secciones agrupadas y
/// cierre de sesión. Se usa dentro del `Drawer` (móvil) o fijo (escritorio).
class BusinessSideMenu extends StatelessWidget {
  const BusinessSideMenu({
    super.key,
    required this.current,
    required this.onSelected,
    required this.onLogout,
    this.locked = const {},
    this.hidden = const {},
  });

  final BusinessSection current;

  /// Secciones bloqueadas hasta terminar la configuración inicial.
  final Set<BusinessSection> locked;

  /// Secciones que no se muestran (módulos no activos).
  final Set<BusinessSection> hidden;
  final ValueChanged<BusinessSection> onSelected;
  final VoidCallback onLogout;

  /// Cierra el drawer (si está abierto) antes de ejecutar la acción.
  void _run(BuildContext context, VoidCallback action) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen ?? false) scaffold!.closeDrawer();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MenuHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              children: [
                for (final group in BusinessSectionGroup.values) ...[
                  _GroupLabel(group.label),
                  for (final section in BusinessSection.values.where(
                    (s) => s.group == group && !hidden.contains(s),
                  ))
                    _MenuItem(
                      icon: section == current
                          ? section.activeIcon
                          : section.icon,
                      label: section.label,
                      selected: section == current,
                      locked: locked.contains(section),
                      onTap: () => _run(context, () {
                        if (section != current) onSelected(section);
                      }),
                    ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.surfaceContainerHigh),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _MenuItem(
                icon: Icons.logout_rounded,
                label: 'Cerrar sesión',
                selected: false,
                foreground: AppColors.statusDue,
                onTap: () => _run(context, onLogout),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // En oscuro, como la barra superior: negro azulado con verde.
          colors: AppColors.isDark
              ? [AppColors.surfaceContainerHigh, AppColors.brandTealLight]
              : [AppColors.brandTeal, AppColors.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Row(
            children: [
              const AppLogoIcon(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi Cancha',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headlineMd.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentLime,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'ADMIN NEGOCIO',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSecondaryFixed,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Semantics(
        header: true,
        child: Text(
          label.toUpperCase(),
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.foreground,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        foreground ??
        (selected ? AppColors.brandTeal : AppColors.onSurfaceVariant);
    final textColor =
        foreground ??
        (selected
            ? AppColors.brandTealDeep
            : locked
            ? AppColors.onSurfaceVariant
            : AppColors.onSurface);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Semantics(
        button: true,
        selected: selected,
        label: locked ? '$label (bloqueado)' : label,
        excludeSemantics: true,
        child: Material(
          color: selected ? AppColors.brandTealLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  // Indicador lima de la sección activa.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 4,
                    height: selected ? 24 : 0,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentLime,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Icon(icon, size: 22, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLg.copyWith(
                        color: textColor,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (locked && !selected)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  if (selected)
                    Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.brandTeal,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
