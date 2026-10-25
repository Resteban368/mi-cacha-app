import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';

/// Cabecera del login de negocio: fondo Negro Azulado de la marca con
/// textura de canchas y el logo vertical.
///
/// En web ([panel]) ocupa todo el espacio que recibe, centra el contenido y
/// suma una línea con la propuesta de valor.
class BusinessLoginHeader extends StatelessWidget {
  const BusinessLoginHeader({super.key, this.onBack, this.panel = false});

  /// Regresa al login de jugador; `null` oculta el botón.
  final VoidCallback? onBack;
  final bool panel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: panel ? StackFit.expand : StackFit.loose,
      children: [
        const Positioned.fill(child: _CourtTexture()),
        // Luces ambientales.
        const Positioned(
          top: -64,
          right: -48,
          child: _Glow(size: 176, color: Color(0x1ACCFF00)),
        ),
        const Positioned(
          top: 40,
          left: -48,
          child: _Glow(size: 144, color: Color(0x1AFFFFFF)),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo vertical de la marca (para fondo oscuro).
                  Image.asset(
                    AppAssets.logoVerticalDark,
                    height: panel ? 170 : 116,
                    semanticLabel: 'Mi Cancha, tus reservas al instante',
                  ),
                  if (panel) ...[
                    const SizedBox(height: 28),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Text(
                        'Administra reservas, cobros y canchas de tu sede '
                        'desde un solo lugar.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (onBack case final onBack?)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: _BackButton(onPressed: onBack),
              ),
            ),
          ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Volver al acceso de jugadores',
      child: Material(
        color: Colors.white.withValues(alpha: 0.15),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: const SizedBox.square(
            dimension: 48,
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Colors.white,
              semanticLabel: 'Volver al acceso de jugadores',
            ),
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// Fondo Negro Azulado (igual en los dos modos, el logo es para fondo
/// oscuro) con gradientes radiales y patrón de líneas de cancha en mosaico.
class _CourtTexture extends StatelessWidget {
  const _CourtTexture();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF0B1F28)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.6, -0.6),
            radius: 0.8,
            colors: [Color(0x1FCCFF00), Color(0x00CCFF00)],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.6, 0.6),
              radius: 1,
              colors: [Color(0x14FFFFFF), Color(0x00FFFFFF)],
            ),
          ),
          child: RepaintBoundary(
            child: CustomPaint(painter: _CourtTilePainter()),
          ),
        ),
      ),
    );
  }
}

class _CourtTilePainter extends CustomPainter {
  const _CourtTilePainter();

  static const _tile = Size(320, 260);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color =
          const Color(0x29FFFFFF) // stroke-opacity 0.16
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final dot = Paint()..color = const Color(0x40FFFFFF);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var y = 0.0; y < size.height; y += _tile.height) {
      for (var x = 0.0; x < size.width; x += _tile.width) {
        canvas
          ..save()
          ..translate(x, y);
        _paintTile(canvas, stroke, dot);
        canvas.restore();
      }
    }
    canvas.restore();
  }

  void _paintTile(Canvas canvas, Paint stroke, Paint dot) {
    canvas
      // Fútbol: medio campo y círculo central
      ..drawLine(const Offset(0, 130), const Offset(320, 130), stroke)
      ..drawCircle(const Offset(160, 130), 48, stroke)
      ..drawCircle(const Offset(160, 130), 3, dot)
      // Baloncesto: zona y arco de triples
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(105, 0, 110, 75),
          const Radius.circular(2),
        ),
        stroke,
      )
      ..drawPath(
        Path()
          ..moveTo(70, 0)
          ..cubicTo(70, 75, 250, 75, 250, 0),
        stroke,
      )
      // Pádel: red
      ..drawLine(const Offset(160, 130), const Offset(160, 240), stroke)
      // Voleibol: línea de ataque
      ..drawLine(const Offset(20, 85), const Offset(300, 85), stroke);

    // Pádel: línea de saque punteada 4/4
    for (var x = 60.0; x < 260; x += 8) {
      canvas.drawLine(Offset(x, 195), Offset(x + 4, 195), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
