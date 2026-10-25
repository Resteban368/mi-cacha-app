import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Tarjeta blanca de las secciones de "Mi cuenta".
class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.child,
    this.elevated = false,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;

  /// Sombra más marcada para la tarjeta destacada (suscripción).
  final bool elevated;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandTeal.withValues(
              alpha: elevated ? 0.10 : 0.06,
            ),
            blurRadius: elevated ? 20 : 12,
            offset: Offset(0, elevated ? 4 : 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Ícono en un cuadro redondeado de color suave.
class AccountIconBox extends StatelessWidget {
  const AccountIconBox({
    super.key,
    required this.icon,
    this.size = 36,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final double size;
  final Color? background;

  Color get _background => background ?? AppColors.surfaceContainerLow;
  final Color? foreground;

  Color get _foreground => foreground ?? AppColors.brandTeal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: size * 0.55, color: _foreground),
    );
  }
}
