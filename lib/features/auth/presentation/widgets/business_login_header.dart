import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';

/// Cabecera teal del login de negocio: textura de canchas, logo y deportes.
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
                  const _LogoBadge(),
                  const SizedBox(height: 12),
                  Text(
                    'Mi Cancha',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 30,
                      height: 36 / 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.75,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Color(0x0D000000),
                          blurRadius: 1,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fútbol · Pádel · Baloncesto · Voleibol',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.emerald100.withValues(alpha: 0.75),
                    ),
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

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accentLimeSignal.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald950.withValues(alpha: 0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 20),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: SvgPicture.asset(AppAssets.logo),
          ),
          const Positioned(top: -4, right: -4, child: _LiveIndicator()),
        ],
      ),
    );
  }
}

/// Punto lima con un "ping" oscuro al centro.
class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator();

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

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
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: AppColors.accentLimeSignal,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.brandTeal, width: 2),
      ),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          final t = Curves.easeOut.transform(_controller.value);
          return Transform.scale(
            scale: 1 + t,
            child: Opacity(opacity: 1 - t, child: child),
          );
        },
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.brandDark,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(dimension: 6),
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

/// Fondo teal con gradientes radiales y patrón de líneas de cancha en mosaico.
class _CourtTexture extends StatelessWidget {
  const _CourtTexture();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: AppColors.brandTeal),
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
