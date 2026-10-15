import 'package:flutter/material.dart';

/// Marca de agua con las líneas de un campo multideporte
/// (fútbol, pádel, básquet). Réplica del SVG del diseño en Stitch.
class CourtWatermark extends StatelessWidget {
  const CourtWatermark({super.key, this.opacity = 0.08});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: const RepaintBoundary(
          child: CustomPaint(
            painter: _CourtWatermarkPainter(),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _CourtWatermarkPainter extends CustomPainter {
  const _CourtWatermarkPainter();

  // Sistema de coordenadas original del SVG (viewBox 0 0 400 800).
  static const _vbWidth = 400.0;
  static const _vbHeight = 800.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Escala "contain" centrada, igual que preserveAspectRatio por defecto.
    final scale = (size.width / _vbWidth) < (size.height / _vbHeight)
        ? size.width / _vbWidth
        : size.height / _vbHeight;
    final dx = (size.width - _vbWidth * scale) / 2;
    final dy = (size.height - _vbHeight * scale) / 2;

    canvas
      ..save()
      ..translate(dx, dy)
      ..scale(scale);

    Paint stroke(double width) => Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    final s3 = stroke(3);
    final s2 = stroke(2);
    final s15 = stroke(1.5);

    // Límites del estadio
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(24, 40, 352, 720),
          const Radius.circular(36),
        ),
        s3,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(40, 60, 320, 680),
          const Radius.circular(20),
        ),
        s2,
      )
      // Mitad de campo y círculo central
      ..drawLine(const Offset(40, 400), const Offset(360, 400), s2)
      ..drawCircle(const Offset(200, 400), 70, s2)
      ..drawCircle(const Offset(200, 400), 5, Paint()..color = Colors.white)
      // Áreas superior e inferior
      ..drawRect(const Rect.fromLTWH(110, 60, 180, 110), s2)
      ..drawRect(const Rect.fromLTWH(145, 60, 110, 48), s2)
      ..drawRect(const Rect.fromLTWH(110, 630, 180, 110), s2)
      ..drawRect(const Rect.fromLTWH(145, 692, 110, 48), s2)
      // Arcos de triple (básquet)
      ..drawPath(
        Path()
          ..moveTo(64, 60)
          ..cubicTo(64, 220, 336, 220, 336, 60),
        s2,
      )
      ..drawPath(
        Path()
          ..moveTo(64, 740)
          ..cubicTo(64, 580, 336, 580, 336, 740),
        s2,
      )
      // Red de pádel / vóley
      ..drawLine(const Offset(200, 280), const Offset(200, 520), s15);

    // Medialunas punteadas
    _drawDashedPath(
      canvas,
      Path()..addArc(
        Rect.fromCircle(center: const Offset(200, 170), radius: 70),
        0,
        3.141592653589793,
      ),
      s2,
      dash: 4,
      gap: 4,
    );
    _drawDashedPath(
      canvas,
      Path()..addArc(
        Rect.fromCircle(center: const Offset(200, 630), radius: 70),
        3.141592653589793,
        3.141592653589793,
      ),
      s2,
      dash: 4,
      gap: 4,
    );
    // Líneas de saque punteadas
    for (final y in const [280.0, 520.0]) {
      _drawDashedPath(
        canvas,
        Path()
          ..moveTo(80, y)
          ..lineTo(320, y),
        s15,
        dash: 6,
        gap: 4,
      );
    }

    canvas.restore();
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
