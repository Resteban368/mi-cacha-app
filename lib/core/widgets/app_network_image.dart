import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'shimmer_box.dart';

/// Imagen de la red con shimmer mientras descarga y un fundido al aparecer.
/// Si falla muestra [error] (por defecto, un ícono de imagen rota).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.semanticLabel,
    this.error,
  });

  final String url;
  final BoxFit fit;

  /// Ancho de decodificación en píxeles (ahorra memoria en miniaturas).
  final int? cacheWidth;
  final String? semanticLabel;
  final Widget? error;

  static const _fadeIn = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: cacheWidth,
      semanticLabel: semanticLabel,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        // Desde la caché aparece al instante, sin shimmer.
        if (wasSynchronouslyLoaded) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (frame == null) const ShimmerBox(),
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: _fadeIn,
              curve: Curves.easeOut,
              child: child,
            ),
          ],
        );
      },
      errorBuilder: (_, _, _) =>
          error ??
          ColoredBox(
            color: AppColors.surfaceContainerLow,
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 32,
                color: AppColors.outline,
              ),
            ),
          ),
    );
  }
}
