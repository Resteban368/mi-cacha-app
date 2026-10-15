import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Cabecera con mosaico multideporte, marca y propuesta de valor.
///
/// En móvil va arriba con [height] fijo; en web ([large]) es un panel lateral
/// que ocupa todo el alto disponible ([height] nulo) con el lema más grande.
class LoginHero extends StatelessWidget {
  const LoginHero({
    super.key,
    this.height,
    this.borderRadius = const BorderRadius.vertical(
      bottom: Radius.circular(36),
    ),
    this.large = false,
  });

  static const _bigMinSize = Size(600, 600);

  final double? height;
  final BorderRadius borderRadius;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: ColoredBox(
          color: AppColors.brandTealDeep,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _PhotoMosaic(),
              // Gradación de color de marca (multiply) + viñeta.
              const DecoratedBox(
                decoration: BoxDecoration(
                  backgroundBlendMode: BlendMode.multiply,
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.brandTealDeep,
                      Color(0xCC0F8B7A),
                      Color(0xBF084C43),
                    ],
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x66000000),
                      Color(0x00000000),
                      Color(0xF2084C43),
                    ],
                  ),
                ),
              ),
              const IgnorePointer(
                child: Opacity(
                  opacity: 0.15,
                  child: CustomPaint(painter: _HeroCourtLinesPainter()),
                ),
              ),
              SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // El lema grande solo si el panel tiene lugar para él.
                    final big =
                        large &&
                        constraints.maxWidth >= _bigMinSize.width &&
                        constraints.maxHeight >= _bigMinSize.height;
                    return Padding(
                      padding: EdgeInsets.all(big ? 40 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const _TopBar(),
                          _Tagline(large: big),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoMosaic extends StatelessWidget {
  const _PhotoMosaic();

  static const _photos = [
    (AppAssets.loginPadel, 0.9),
    (AppAssets.loginFutbol, 0.85),
    (AppAssets.loginBasket, 0.85),
    (AppAssets.loginVoley, 0.9),
  ];

  @override
  Widget build(BuildContext context) {
    Widget tile(int i) => Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: _photos[i].$2,
          child: Image.asset(
            _photos[i].$1,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            // Fotos de 512px: suficiente para media pantalla.
            cacheWidth: 512,
            gaplessPlayback: true,
          ),
        ),
      ),
    );

    return Transform.scale(
      scale: 1.05,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [tile(0), const SizedBox(width: 6), tile(1)],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                children: [tile(2), const SizedBox(width: 6), tile(3)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassPill(
            color: AppColors.brandTealDeep.withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SvgPicture.asset(AppAssets.logo, width: 28),
                ),
                const SizedBox(width: 10),
                Text(
                  'Mi Cancha',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline({required this.large});

  final bool large;

  @override
  Widget build(BuildContext context) {
    final title =
        (large
                ? AppTypography.displayLg.copyWith(fontSize: 48)
                : AppTypography.displayLgMobile)
            .copyWith(color: AppColors.onPrimary, height: large ? 1.15 : 1.25);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentLimeSignal,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bolt,
                  size: 15,
                  color: AppColors.onSecondaryFixed,
                ),
                const SizedBox(width: 4),
                Text(
                  'ACCESO INSTANTÁNEO',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSecondaryFixed,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: title,
              children: [
                const TextSpan(text: 'Tu próxima cancha,\n'),
                TextSpan(
                  text: 'a un toque.',
                  style: title.copyWith(
                    color: AppColors.accentLimeSignal,
                    // decoration: TextDecoration.underline,
                    decorationColor: AppColors.accentLimeSignal.withValues(
                      alpha: 0.4,
                    ),
                    decorationThickness: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: large ? 440 : 320),
            child: Text(
              'Reserva en segundos en las canchas de tu ciudad sin esperas ni llamadas.',
              style: (large ? AppTypography.bodyLg : AppTypography.bodyMd)
                  .copyWith(
                    color: AppColors.surfaceBright.withValues(alpha: 0.9),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.color,
    required this.padding,
    required this.child,
  });

  final Color color;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: ColoredBox(
          color: color,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _HeroCourtLinesPainter extends CustomPainter {
  const _HeroCourtLinesPainter();

  static const _vbWidth = 390.0;
  static const _vbHeight = 500.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / _vbWidth) < (size.height / _vbHeight)
        ? size.width / _vbWidth
        : size.height / _vbHeight;
    canvas
      ..save()
      ..translate(
        (size.width - _vbWidth * scale) / 2,
        (size.height - _vbHeight * scale) / 2,
      )
      ..scale(scale);

    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final limeStroke = Paint()
      ..color = AppColors.accentLimeSignal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final limeFill = Paint()..color = AppColors.accentLimeSignal;

    // Borde punteado 8/6
    final border = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(25, 30, 340, 440),
          const Radius.circular(28),
        ),
      );
    for (final metric in border.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 14) {
        canvas.drawPath(metric.extractPath(d, d + 8), limeStroke);
      }
    }

    canvas
      ..drawLine(const Offset(25, 250), const Offset(365, 250), white)
      ..drawCircle(const Offset(195, 250), 64, white)
      ..drawCircle(const Offset(195, 250), 6, limeFill)
      ..drawCircle(const Offset(95, 130), 5, limeFill)
      ..drawCircle(const Offset(295, 370), 5, limeFill)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
