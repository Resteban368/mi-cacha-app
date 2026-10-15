import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Punto con pulso de opacidad (equivale a `animate-pulse` de Tailwind).
/// Respeta "reducir movimiento" del sistema.
class PulsingDot extends StatefulWidget {
  const PulsingDot({
    super.key,
    this.size = 8,
    this.color = AppColors.accentLimeSignal,
  });

  final double size;
  final Color color;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
    lowerBound: 0.5,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: DecoratedBox(
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        child: SizedBox.square(dimension: widget.size),
      ),
    );
  }
}
