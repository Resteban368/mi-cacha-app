import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pulsing_dot.dart';
import 'onboarding_common.dart';

/// Paso 2 · "Mira la disponibilidad al instante".
class OnboardingStepAvailability extends StatelessWidget {
  const OnboardingStepAvailability({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      horizontalPadding: 12,
      footer: Column(
        children: [
          const OnboardingDots(activeIndex: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Tooltip(
                message: 'Volver',
                child: Material(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onBack,
                    child: const SizedBox(
                      width: 56,
                      height: 52,
                      child: Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: AppColors.onSurface,
                        semanticLabel: 'Volver',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OnboardingPrimaryButton(
                  onPressed: onNext,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Siguiente'),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: AppColors.accentLime,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      header: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: const OnboardingBrand(icon: Icons.sports_soccer_outlined),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerHigh,
                foregroundColor: AppColors.onSurfaceVariant,
                textStyle: AppTypography.labelMd,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(48, 32),
              ),
              child: const Text('Saltar'),
            ),
          ],
        ),
      ),
      media: const _CalendarCard(),
      children: [
        const OnboardingBlock(
          child: OnboardingStepPill(
            icon: Icons.schedule,
            label: 'Paso 2 de 3 · Tiempo Real',
            background: AppColors.accentLimeTint,
            foreground: AppColors.brandTealDeep,
            iconColor: AppColors.brandTeal,
          ),
        ),
        const OnboardingGap(4),
        OnboardingTitle(
          'Mira la disponibilidad al instante',
          maxWidth: 320,
          style: AppTypography.headlineLg,
        ),
        const OnboardingGap(4),
        OnboardingDescription(
          'Sin escribir por WhatsApp ni esperar confirmación de nadie.',
          style: AppTypography.bodyLg,
        ),
      ],
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -48,
            right: -48,
            child: AmbientGlow(
              size: 176,
              color: AppColors.accentLime.withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            bottom: -32,
            left: -32,
            child: AmbientGlow(
              size: 160,
              color: AppColors.brandTeal.withValues(alpha: 0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(
                      background: AppColors.surfaceContainerLowest,
                      shadow: true,
                      children: [
                        const PulsingDot(size: 10),
                        const SizedBox(width: 6),
                        Text(
                          '100% EN VIVO',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.brandTealDeep,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    _Chip(
                      background: AppColors.brandTealLight,
                      horizontalPadding: 10,
                      children: [
                        const Icon(
                          Icons.bolt,
                          size: 16,
                          color: AppColors.brandTeal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cupos Reales',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.brandTeal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: SvgPicture.asset(
                      AppAssets.onboardingCalendario,
                      semanticsLabel:
                          'Calendario con horarios libres y tu turno elegido',
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Expanded(
                      child: _LegendPill(
                        color: AppColors.brandTeal,
                        label: 'Canchas sintéticas',
                      ),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: _LegendPill(
                        color: AppColors.accentLimeSignal,
                        label: 'Actualización en vivo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.background,
    required this.children,
    this.horizontalPadding = 12,
    this.shadow = false,
  });

  final Color background;
  final List<Widget> children;
  final double horizontalPadding;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const SizedBox.square(dimension: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
