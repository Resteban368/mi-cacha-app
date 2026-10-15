import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Isotipo de Mi Cancha: cancha estilizada con nodos lima
/// y un indicador "ping" en la esquina superior derecha.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 112, this.animate = true});

  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.214; // rounded-3xl (24px) sobre 112px
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.brandTeal.withValues(alpha: 0.8),
                  AppColors.brandTealDeep,
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 50,
                  offset: Offset(0, 25),
                  spreadRadius: -12,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brandTeal,
                borderRadius: BorderRadius.circular(radius - 2),
              ),
              child: const CustomPaint(
                painter: _CourtIconPainter(),
                size: Size.infinite,
              ),
            ),
          ),
          Positioned(top: -4, right: -4, child: _LimePing(animate: animate)),
        ],
      ),
    );
  }
}

class _LimePing extends StatefulWidget {
  const _LimePing({required this.animate});

  final bool animate;

  @override
  State<_LimePing> createState() => _LimePingState();
}

class _LimePingState extends State<_LimePing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
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
    const dotSize = 16.0;
    return SizedBox.square(
      dimension: dotSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Equivalente a `animate-ping` de Tailwind: escala 1→2 y se desvanece.
          AnimatedBuilder(
            animation: _controller,
            builder: (_, child) {
              final t = Curves.easeOut.transform(_controller.value);
              return Transform.scale(
                scale: 1 + t,
                child: Opacity(opacity: 0.75 * (1 - t), child: child),
              );
            },
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.accentLime,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: dotSize),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.accentLimeSignal,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(dimension: dotSize),
          ),
        ],
      ),
    );
  }
}

class _CourtIconPainter extends CustomPainter {
  const _CourtIconPainter();

  static const _vb = 120.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _vb;
    canvas
      ..save()
      ..translate(
        (size.width - _vb * scale) / 2,
        (size.height - _vb * scale) / 2,
      )
      ..scale(scale);

    Paint stroke(double width, [double opacity = 1]) => Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width;

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(8, 8, 104, 104),
          const Radius.circular(20),
        ),
        stroke(5),
      )
      ..drawLine(const Offset(60, 8), const Offset(60, 112), stroke(4.5))
      ..drawPath(
        Path()
          ..moveTo(28, 8)
          ..cubicTo(28, 42, 92, 42, 92, 8),
        stroke(4, 0.85),
      )
      ..drawPath(
        Path()
          ..moveTo(28, 112)
          ..cubicTo(28, 78, 92, 78, 92, 112),
        stroke(4, 0.85),
      )
      ..drawCircle(const Offset(60, 60), 23, stroke(4, 0.9));

    final lime = Paint()..color = AppColors.accentLimeSignal;
    final shadow = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    for (final (center, r) in const [
      (Offset(91, 28), 6.5),
      (Offset(60, 60), 6.0),
      (Offset(31, 90), 6.5),
    ]) {
      canvas
        ..drawCircle(center.translate(0, 1), r, shadow)
        ..drawCircle(center, r, lime);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
