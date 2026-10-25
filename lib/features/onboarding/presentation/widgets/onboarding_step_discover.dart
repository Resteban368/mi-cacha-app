import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pulsing_dot.dart';
import 'onboarding_common.dart';

/// Paso 1 · "Todas las canchas de tu ciudad".
class OnboardingStepDiscover extends StatelessWidget {
  const OnboardingStepDiscover({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const OnboardingDots(activeIndex: 0, spacing: 6),
          OnboardingPrimaryButton(
            onPressed: onNext,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Siguiente'),
                SizedBox(width: 12),
                LimeArrowBadge(),
              ],
            ),
          ),
        ],
      ),
      header: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: const OnboardingBrand(icon: Icons.sports_soccer, size: 32),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandTeal,
                textStyle: AppTypography.labelLg,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Saltar'),
            ),
          ],
        ),
      ),
      media: const _CityIllustration(),
      children: [
        OnboardingBlock(
          child: OnboardingStepPill(
            icon: Icons.explore,
            label: 'Paso 1 de 3 • Descubre',
            background: AppColors.brandTealLight,
            foreground: AppColors.brandTeal,
          ),
        ),
        const OnboardingGap(8),
        OnboardingTitle(
          'Todas las canchas de tu ciudad',
          maxWidth: 320,
          style: AppTypography.displayLgMobile,
        ),
        const OnboardingGap(8),
        OnboardingDescription(
          'Fútbol, pádel, baloncesto, vóley playa y más, en un solo lugar '
          'y en tiempo real.',
          style: AppTypography.bodyMd.copyWith(height: 1.625),
        ),
        const OnboardingGap(12),
        const OnboardingBlock(
          maxWidth: 340,
          wideMaxWidth: 400,
          child: Row(
            children: [
              Expanded(
                child: FeatureTile(icon: Icons.sports_soccer, label: 'Fútbol'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: FeatureTile(icon: Icons.sports_tennis, label: 'Pádel'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: FeatureTile(
                  icon: Icons.sports_basketball,
                  label: 'Básquet',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: FeatureTile(
                  icon: Icons.sports_volleyball,
                  label: 'Vóley',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CityIllustration extends StatelessWidget {
  const _CityIllustration();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 340),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Opacity(
                opacity: 0.2,
                child: CustomPaint(painter: _DotGridPainter()),
              ),
              SvgPicture.asset(
                AppAssets.onboardingCiudad,
                fit: BoxFit.contain,
                semanticsLabel:
                    'Mapa de la ciudad con canchas de fútbol, pádel y vóley',
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 6,
                        offset: Offset(0, 4),
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PulsingDot(),
                      const SizedBox(width: 6),
                      Text(
                        '14 canchas cerca de ti',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Patrón de puntos teal cada 16px.
class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.brandTeal;
    for (var y = 8.0; y < size.height; y += 16) {
      for (var x = 8.0; x < size.width; x += 16) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
