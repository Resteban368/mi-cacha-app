import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';

/// Ícono redondeado de la marca (el de la app). El contorno cambia con el
/// modo: blanco suave en claro y verde suave en oscuro, para que el ícono
/// (oscuro) se separe del fondo.
class AppLogoIcon extends StatelessWidget {
  const AppLogoIcon({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final outline = AppColors.isDark
        ? AppColors.brandTealGlow.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.7);
    // Radio del ícono (esquinas tipo "squircle" del diseño).
    final radius = BorderRadius.circular(size * 0.24);
    return Semantics(
      image: true,
      label: 'Mi Cancha',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: outline, width: size >= 40 ? 2 : 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Image.asset(
            AppAssets.logoRounded,
            width: size,
            height: size,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
