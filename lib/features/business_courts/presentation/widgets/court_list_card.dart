import 'package:flutter/material.dart';

import '../../../../core/domain/entities/sport.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/court.dart';
import '../../../../core/widgets/app_network_image.dart';
import 'court_summaries.dart';

/// Tarjeta de una cancha en la lista: foto principal, estado, horario,
/// precio y las acciones "Usar como base" y "Editar" (tocar la tarjeta
/// también la edita).
class CourtListCard extends StatelessWidget {
  const CourtListCard({
    super.key,
    required this.court,
    required this.onEdit,
    required this.onUseAsBase,
  });

  /// Alto fijo para la cuadrícula.
  static const height = 236.0;

  final Court court;

  /// `null` en solo lectura: la tarjeta no ofrece acciones.
  final VoidCallback? onEdit;
  final VoidCallback? onUseAsBase;

  static IconData _sportIcon(Sport? sport) => switch (sport) {
    Sport.futbol => Icons.sports_soccer,
    Sport.padel => Icons.sports_tennis,
    Sport.baloncesto => Icons.sports_basketball,
    Sport.voleibol => Icons.sports_volleyball,
    null => Icons.stadium_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final photo = court.photos[CourtPhotoSlot.main];
    final missing = court.missingPhotos.length;
    final (statusLabel, statusColor, statusBackground) = switch (court) {
      Court(isActive: false) => (
        'Inactiva',
        AppColors.onSurfaceVariant,
        AppColors.surfaceContainerHigh,
      ),
      Court(isBookable: true) => (
        'Lista para reservas',
        AppColors.brandTealDeep,
        AppColors.brandTealLight,
      ),
      _ => (
        switch (missing) {
          0 => 'Incompleta',
          1 => 'Falta 1 foto',
          _ => 'Faltan $missing fotos',
        },
        AppColors.onErrorContainer,
        AppColors.errorContainer,
      ),
    };
    final detail = AppTypography.bodySm.copyWith(
      color: AppColors.onSurfaceVariant,
    );

    return Semantics(
      container: true,
      label: '${court.name}, $statusLabel',
      child: Container(
        clipBehavior: Clip.antiAlias,
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
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onEdit,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        // Más angosta en pantallas muy chicas (320 px).
                        width: MediaQuery.sizeOf(context).width < 360
                            ? 80
                            : 112,
                        child: ColoredBox(
                          color: AppColors.surfaceContainerLow,
                          child: photo == null
                              ? Icon(
                                  _sportIcon(court.sport),
                                  size: 40,
                                  color: AppColors.brandTeal,
                                )
                              : AppNetworkImage(
                                  photo,
                                  // Miniatura: ~112 px a 3x de densidad.
                                  cacheWidth: 336,
                                  semanticLabel: 'Foto de ${court.name}',
                                  error: Icon(
                                    _sportIcon(court.sport),
                                    size: 40,
                                    color: AppColors.brandTeal,
                                  ),
                                ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                court.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.headlineSm.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${CourtSummaries.sport(court.sport)} · '
                                '${court.isCovered ? 'Cubierta' : 'Al aire libre'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: detail,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBackground,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: AppTypography.labelSm.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              _Line(
                                icon: Icons.schedule,
                                text: CourtSummaries.schedule(court.schedules),
                              ),
                              _Line(
                                icon: Icons.payments_outlined,
                                text: CourtSummaries.pricing(court),
                              ),
                              _Line(
                                icon: Icons.local_offer_outlined,
                                text: CourtSummaries.rates(court.rates.length),
                              ),
                              if (court.specs.label(court.sport)
                                  case final specs when specs.isNotEmpty)
                                _Line(icon: Icons.grass_outlined, text: specs),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onEdit != null || onUseAsBase != null) ...[
                  Divider(
                    height: 1,
                    color: AppColors.surfaceContainerHigh,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: TextButton.icon(
                            onPressed: onUseAsBase,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.onSurfaceVariant,
                              visualDensity: VisualDensity.compact,
                              textStyle: AppTypography.labelMd,
                            ),
                            icon: const Icon(Icons.copy_all_outlined, size: 18),
                            label: const Text(
                              'Usar como base',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton.icon(
                          key: Key('edit-court-${court.id}'),
                          onPressed: onEdit,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.brandTeal,
                            visualDensity: VisualDensity.compact,
                            textStyle: AppTypography.labelMd,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text(
                            'Editar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
