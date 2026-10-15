import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../navigation/business_section.dart';

/// Contenido del menú lateral: cabecera de marca, secciones agrupadas y
/// cierre de sesión. Se usa dentro del `Drawer` (móvil) o fijo (escritorio).
class BusinessSideMenu extends StatelessWidget {
  const BusinessSideMenu({
    super.key,
    required this.current,
    required this.onSelected,
    required this.onLogout,
  });

  final BusinessSection current;
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
                    (s) => s.group == group,
                  ))
                    _MenuItem(
                      icon: section == current
                          ? section.activeIcon
                          : section.icon,
                      label: section.label,
                      selected: section == current,
                      onTap: () => _run(context, () {
                        if (section != current) onSelected(section);
                      }),
                    ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceContainerHigh),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandTeal, AppColors.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accentLimeSignal.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: SvgPicture.asset(AppAssets.logo),
              ),
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
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        foreground ??
        (selected ? AppColors.brandTeal : AppColors.onSurfaceVariant);
    final textColor =
        foreground ??
        (selected ? AppColors.brandTealDeep : AppColors.onSurface);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
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
                  if (selected)
                    const Padding(
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
