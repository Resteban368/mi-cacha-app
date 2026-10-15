import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Loader de tres puntos que rebotan con desfase (blanco, lima, blanco).
class BouncingDotsLoader extends StatefulWidget {
  const BouncingDotsLoader({super.key, this.animate = true});

  final bool animate;

  @override
  State<BouncingDotsLoader> createState() => _BouncingDotsLoaderState();
}

class _BouncingDotsLoaderState extends State<BouncingDotsLoader>
    with SingleTickerProviderStateMixin {
  static const _period = Duration(milliseconds: 900);
  static const _dotSize = 8.0;
  static const _bounceHeight = 6.0;
  // Desfase de cada punto como fracción del período (0s, 0.16s, 0.32s).
  static const _phases = [0.0, 0.16 / 0.9, 0.32 / 0.9];
  static final _colors = [
    AppColors.onPrimary.withValues(alpha: 0.9),
    AppColors.accentLime,
    AppColors.onPrimary.withValues(alpha: 0.9),
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando',
      child: SizedBox(
        height: _dotSize + _bounceHeight,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Transform.translate(
                  offset: Offset(0, -_offsetFor(_phases[i])),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: _dotSize),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _offsetFor(double phase) {
    final t = (_controller.value - phase) % 1.0;
    return math.sin(t * math.pi).abs() * _bounceHeight;
  }
}
