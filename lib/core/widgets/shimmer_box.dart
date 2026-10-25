import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rectángulo con brillo que se desliza: marcador mientras carga contenido.
/// Con "reducir movimiento" activado queda estático.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.borderRadius = BorderRadius.zero});

  final BorderRadius borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  static Color get _base => AppColors.surfaceContainerHigh;
  static Color get _highlight => AppColors.surfaceContainerLowest;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando imagen',
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [_base, _highlight, _base],
                stops: const [0.35, 0.5, 0.65],
                transform: _SlideGradient(_controller.value),
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// Desplaza el degradado de izquierda (-1) a derecha (+1) del ancho.
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.progress);

  final double progress;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (progress * 2 - 1), 0, 0);
}
