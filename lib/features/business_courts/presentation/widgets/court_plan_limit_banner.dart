import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Banner de validación y estado de capacidad de canchas según el plan de suscripción.
class CourtPlanLimitBanner extends StatelessWidget {
  const CourtPlanLimitBanner({
    super.key,
    required this.courtsInUse,
    required this.courtLimit,
    this.planName = 'Plan Pro',
    this.onUpgradePlan,
    this.upgradeLabel = 'Mejorar plan de suscripción',
    this.noActivePlan = false,
  });

  final int courtsInUse;
  final int courtLimit;
  final String planName;

  /// `null` oculta el botón (p. ej. ya tiene el plan más alto).
  final VoidCallback? onUpgradePlan;
  final String upgradeLabel;

  /// Sin suscripción activa: no se pueden habilitar canchas.
  final bool noActivePlan;

  bool get isLimitReached =>
      noActivePlan || (courtLimit > 0 && courtsInUse >= courtLimit);

  @override
  Widget build(BuildContext context) {
    if (isLimitReached) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.statusDue.withValues(alpha: 0.4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.statusDue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.statusDue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        noActivePlan
                            ? 'Sin plan activo'
                            : 'Límite de canchas alcanzado',
                        style: AppTypography.headlineSm.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        noActivePlan
                            ? 'Necesitas un plan activo para habilitar canchas.'
                            : 'Has usado $courtsInUse de $courtLimit canchas '
                                  'disponibles en tu $planName.',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              onUpgradePlan == null
                  ? 'Puedes crear esta cancha como inactiva y habilitarla '
                        'cuando desactives otra.'
                  : 'Puedes crear esta cancha como inactiva y habilitarla '
                        'cuando amplíes tu suscripción.',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (onUpgradePlan != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onUpgradePlan,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.statusDue,
                  foregroundColor: AppColors.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size.fromHeight(40),
                  textStyle: AppTypography.labelMd,
                ),
                icon: const Icon(Icons.upgrade_rounded, size: 18),
                label: Text(upgradeLabel),
              ),
            ],
          ],
        ),
      );
    }

    final remaining = (courtLimit - courtsInUse).clamp(0, courtLimit);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.brandTealLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stadium_outlined,
              color: AppColors.brandTeal,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$planName · $courtsInUse de $courtLimit canchas usadas',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  remaining == 1
                      ? 'Te queda 1 cupo disponible'
                      : 'Te quedan $remaining cupos disponibles',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.brandTeal,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandTealLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$courtsInUse/$courtLimit',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
