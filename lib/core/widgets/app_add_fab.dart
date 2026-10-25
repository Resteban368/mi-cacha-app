import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Botón flotante circular "+" (teal con círculo lima). Solo ícono: el
/// [tooltip] le da nombre accesible.
class AppAddFab extends StatelessWidget {
  const AppAddFab({super.key, required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 25,
              offset: const Offset(0, 16),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Material(
          color: AppColors.primary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 56,
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.accentLime,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: 22,
                    color: AppColors.inverseSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
