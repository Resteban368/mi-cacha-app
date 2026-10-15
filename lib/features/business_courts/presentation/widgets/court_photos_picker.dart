import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_border_box.dart';
import '../../domain/entities/court.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Fotos de la cancha: la principal grande y las otras 4 en cuadrícula
/// (2×2 en el celular, una fila de 4 en web). Las 3 primeras son
/// obligatorias para que la cancha reciba reservas.
class CourtPhotosPicker extends StatelessWidget {
  const CourtPhotosPicker({
    super.key,
    required this.photos,
    this.remotePhotos = const {},
    required this.onPick,
    required this.onRemove,
    this.failed = const {},
    this.enabled = true,
  });

  /// Foto elegida (aún sin subir) por posición.
  final Map<CourtPhotoSlot, Uint8List> photos;

  /// Fotos ya subidas (URL), al editar. Una foto elegida la reemplaza.
  final Map<CourtPhotoSlot, String> remotePhotos;
  final ValueChanged<CourtPhotoSlot> onPick;
  final ValueChanged<CourtPhotoSlot> onRemove;

  /// Posiciones cuya subida falló (se marcan para reintentar).
  final Set<CourtPhotoSlot> failed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    bool has(CourtPhotoSlot slot) =>
        photos.containsKey(slot) || remotePhotos.containsKey(slot);
    final requiredCount = CourtPhotoSlot.required.where(has).length;
    final complete = requiredCount == CourtPhotoSlot.required.length;

    Widget slot(CourtPhotoSlot slot, {required double height}) => _PhotoSlot(
      slot: slot,
      bytes: photos[slot],
      url: photos.containsKey(slot) ? null : remotePhotos[slot],
      failed: failed.contains(slot),
      height: height,
      onPick: enabled ? () => onPick(slot) : null,
      onRemove: enabled ? () => onRemove(slot) : null,
    );

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'FOTOS DE LA CANCHA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: complete
                          ? AppColors.brandTealLight
                          : AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$requiredCount/3 obligatorias',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSm.copyWith(
                        color: complete
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'JPG o PNG de hasta 4 MB. Sin las 3 obligatorias (principal, '
            'superficie e iluminación) la cancha no recibe reservas.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          slot(CourtPhotoSlot.main, height: 160),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) => GridView.count(
              crossAxisCount: constraints.maxWidth >= 520 ? 4 : 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final s in CourtPhotoSlot.values.skip(1))
                  slot(s, height: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.slot,
    required this.bytes,
    required this.url,
    required this.failed,
    required this.height,
    required this.onPick,
    required this.onRemove,
  });

  final CourtPhotoSlot slot;
  final Uint8List? bytes;
  final String? url;
  final bool failed;
  final double height;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  bool get _isMain => slot == CourtPhotoSlot.main;

  @override
  Widget build(BuildContext context) {
    final image = bytes;
    final remote = url;
    if (image != null || remote != null) {
      return Semantics(
        label: '${slot.label}: cargada',
        child: SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Material(
                  color: AppColors.surfaceContainerLow,
                  child: InkWell(
                    onTap: onPick,
                    child: image != null
                        ? Image.memory(
                            image,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.outline,
                            ),
                          )
                        : AppNetworkImage(remote!),
                  ),
                ),
                if (failed)
                  const IgnorePointer(
                    child: ColoredBox(
                      color: Color(0x66B3261E),
                      child: Center(
                        child: Icon(Icons.cloud_off, color: AppColors.onError),
                      ),
                    ),
                  ),
                // A la izquierda del botón de quitar, sin taparse.
                Positioned(
                  left: 8,
                  right: 44,
                  top: 8,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _Badge(text: _isMain ? slot.label : slot.hint),
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton.filled(
                    tooltip: 'Quitar ${slot.label}',
                    onPressed: onRemove,
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xB3000000),
                      foregroundColor: AppColors.onPrimary,
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: 'Subir ${slot.label}: ${slot.hint}',
      excludeSemantics: true,
      child: DashedBorderBox(
        backgroundColor: AppColors.surfaceContainerLow.withValues(
          alpha: slot.isRequired ? 0.7 : 0.4,
        ),
        color: failed
            ? AppColors.statusDue
            : _isMain
            ? AppColors.brandTeal.withValues(alpha: 0.4)
            : AppColors.outlineVariant,
        radius: 12,
        strokeWidth: slot.isRequired ? 1.5 : 1,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: slot.isRequired
                            ? AppColors.brandTealLight
                            : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        slot.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSm.copyWith(
                          color: slot.isRequired
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: _isMain ? 10 : 6),
                    Icon(
                      _isMain ? Icons.add_a_photo_outlined : Icons.add,
                      size: _isMain ? 28 : 20,
                      color: slot.isRequired
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slot.hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xB3000000),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelSm.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
