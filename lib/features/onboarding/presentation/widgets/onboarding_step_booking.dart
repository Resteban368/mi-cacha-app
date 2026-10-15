import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/pulsing_dot.dart';
import 'onboarding_common.dart';

/// Paso 3 · "Reserva en segundos".
class OnboardingStepBooking extends StatelessWidget {
  const OnboardingStepBooking({
    super.key,
    required this.onStart,
    required this.onLogin,
  });

  final VoidCallback onStart;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepLayout(
      horizontalPadding: 12,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: OnboardingDots(activeIndex: 2)),
          const SizedBox(height: 16),
          OnboardingPrimaryButton(
            onPressed: onStart,
            height: 54,
            shadowOpacity: 0.15,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('EMPEZAR AHORA'),
                SizedBox(width: 8),
                LimeArrowBadge(iconColor: AppColors.onSecondaryFixed),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Text(
                '¿Ya tienes cuenta?',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: onLogin,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandTeal,
                  textStyle: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(48, 40),
                ),
                child: const Text('Inicia Sesión'),
              ),
            ],
          ),
        ],
      ),
      header: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: OnboardingBrand(
                icon: Icons.sports_tennis,
                background: AppColors.primary,
                titleColor: AppColors.brandTealDeep,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandTeal.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                    spreadRadius: -1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PulsingDot(),
                  const SizedBox(width: 6),
                  Text(
                    'Listo para jugar',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      media: const _TicketIllustration(),
      mediaSpacing: 8,
      children: [
        OnboardingBlock(
          child: OnboardingStepPill(
            icon: Icons.verified,
            label: 'Confirmación Instantánea',
            background: AppColors.accentLimeTint,
            foreground: AppColors.brandTealDeep,
            iconColor: AppColors.brandTeal,
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        const OnboardingGap(8),
        OnboardingTitle(
          'Reserva en segundos',
          style: AppTypography.displayLgMobile,
        ),
        const OnboardingGap(4),
        OnboardingDescription(
          'Elige tu horario, paga el anticipo y listo. Recibes tu código '
          'de acceso al instante sin esperas ni llamadas.',
          maxWidth: 320,
          style: AppTypography.bodyMd,
        ),
        const OnboardingGap(12),
        OnboardingBlock(
          maxWidth: 320,
          wideMaxWidth: 420,
          child: Row(
            children: [
              for (final (i, tile) in const [
                (Icons.timer_outlined, '1 Minuto', 'Proceso ágil'),
                (
                  Icons.account_balance_wallet_outlined,
                  'Anticipo Seguro',
                  'PSE / Nequi',
                ),
                (Icons.key_outlined, 'Pase Digital', 'Acceso directo'),
              ].indexed) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: FeatureTile(
                    icon: tile.$1,
                    label: tile.$2,
                    caption: tile.$3,
                    iconSize: 20,
                    iconColor: i == 1
                        ? AppColors.statusPaid
                        : AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    shadow: false,
                    labelStyle: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TicketIllustration extends StatelessWidget {
  const _TicketIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 384),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -16,
              left: -16,
              child: AmbientGlow(
                size: 112,
                color: AppColors.accentLime.withValues(alpha: 0.2),
              ),
            ),
            Positioned(
              bottom: -24,
              right: -24,
              child: AmbientGlow(
                size: 144,
                color: AppColors.brandTealGlow.withValues(alpha: 0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SvgPicture.asset(
                  AppAssets.onboardingReserva,
                  semanticsLabel:
                      'Teléfono con reserva confirmada, código QR y PIN de ingreso',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
