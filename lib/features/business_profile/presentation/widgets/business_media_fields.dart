import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_border_box.dart';
import '../../../../core/config/map_config.dart';
import '../../../../core/location/geo_point.dart';
import '../bloc/business_profile_bloc.dart';
import '../../../../core/widgets/app_network_image.dart';
import 'business_form_label.dart';
import 'osm_attribution.dart';
import 'osm_tile_layer.dart';

/// Foto de portada de la sede: zona para subirla o la foto actual con
/// acciones para cambiarla o quitarla.
class CoverPhotoField extends StatelessWidget {
  const CoverPhotoField({
    super.key,
    required this.onPick,
    required this.onRemove,
    this.imageUrl,
    this.pendingBytes,
    this.status = BusinessCoverStatus.idle,
  });

  static const _height = 176.0;

  final VoidCallback onPick;
  final VoidCallback onRemove;

  /// Foto ya subida (HTTPS, pública).
  final String? imageUrl;

  /// Foto elegida antes de registrar el negocio (aún no subida).
  final Uint8List? pendingBytes;
  final BusinessCoverStatus status;

  @override
  Widget build(BuildContext context) {
    final pending = pendingBytes;
    final url = imageUrl;
    final hasPhoto = pending != null || url != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BusinessFormLabel(
          'Foto o portada de la sede',
          trailing: pending != null
              ? Text(
                  'Se subirá al guardar',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 6),
        if (!hasPhoto)
          _EmptyCover(onTap: status.isBusy ? null : onPick)
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: _height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: AppColors.surfaceContainerLow,
                    child: pending != null
                        ? Image.memory(
                            pending,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (_, _, _) => const _BrokenImage(),
                          )
                        : AppNetworkImage(
                            url!,
                            semanticLabel: 'Foto de portada de la sede',
                            error: const _BrokenImage(),
                          ),
                  ),
                  if (status.isBusy)
                    _BusyOverlay(
                      label: status == BusinessCoverStatus.removing
                          ? 'Quitando foto…'
                          : 'Subiendo foto…',
                    )
                  else
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Row(
                        children: [
                          _CoverAction(
                            icon: Icons.delete_outline,
                            label: 'Quitar',
                            onPressed: onRemove,
                          ),
                          const SizedBox(width: 8),
                          _CoverAction(
                            icon: Icons.photo_camera_outlined,
                            label: 'Cambiar',
                            onPressed: onPick,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyCover extends StatelessWidget {
  const _EmptyCover({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Subir foto de portada o logo',
      excludeSemantics: true,
      child: DashedBorderBox(
        backgroundColor: AppColors.surfaceContainerLow,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: CoverPhotoField._height,
              child: onTap == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandTeal,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _IconBubble(
                          icon: Icons.add_a_photo_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Subir foto de portada o logo',
                          textAlign: TextAlign.center,
                          style: AppTypography.labelLg.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Formatos JPG o PNG hasta 4 MB',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  const _BrokenImage();

  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(
      Icons.broken_image_outlined,
      size: 32,
      color: AppColors.outline,
    ),
  );
}

/// Botón translúcido sobre la foto.
class _CoverAction extends StatelessWidget {
  const _CoverAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.onSurface.withValues(alpha: 0.72),
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: const StadiumBorder(),
        textStyle: AppTypography.labelMd,
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _BusyOverlay extends StatelessWidget {
  const _BusyOverlay({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x99000000),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTypography.labelMd.copyWith(color: AppColors.onPrimary),
          ),
        ],
      ),
    );
  }
}

/// Círculo de 48px con ícono (estados vacíos del formulario).
class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Icon(icon, size: 24, color: color),
    );
  }
}

/// Ubicación y punto de llegada: sin fijar invita a ubicar el pin; fijada
/// muestra un mapa con el pin y permite cambiarla o quitarla.
class LocationField extends StatelessWidget {
  const LocationField({
    super.key,
    required this.location,
    required this.onPinTap,
    required this.onClear,
    this.tileProvider,
  });

  final GeoPoint? location;
  final VoidCallback onPinTap;
  final VoidCallback onClear;

  /// Solo para tests (teselas sin red).
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    final point = location;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BusinessFormLabel(
          'Ubicación y punto de llegada',
          trailing: Text(
            point == null ? 'Sin fijar' : 'Fijada',
            style: AppTypography.labelSm.copyWith(
              color: point == null ? AppColors.outline : AppColors.brandTeal,
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (point == null)
          _EmptyLocation(onPinTap: onPinTap)
        else
          _LocationPreview(
            point: point,
            tileProvider: tileProvider,
            onChange: onPinTap,
            onClear: onClear,
          ),
      ],
    );
  }
}

class _LocationPreview extends StatelessWidget {
  const _LocationPreview({
    required this.point,
    required this.tileProvider,
    required this.onChange,
    required this.onClear,
  });

  final GeoPoint point;
  final TileProvider? tileProvider;
  final VoidCallback onChange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final latLng = LatLng(point.latitude, point.longitude);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 185,
            child: Semantics(
              label: 'Mapa con el punto de llegada de la sede',
              child: Stack(
                children: [
                  FlutterMap(
                    key: ValueKey(point),
                    options: MapOptions(
                      initialCenter: latLng,
                      initialZoom: MapConfig.pointZoom - 1,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      OsmTileLayer(tileProvider: tileProvider),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: latLng,
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.6),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.brandTeal,
                                        AppColors.primary,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x33000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const OsmAttribution(),
                    ],
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest.withValues(
                          alpha: 0.92,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Punto de llegada',
                            style: AppTypography.labelSm.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                const Icon(
                  Icons.place_rounded,
                  size: 18,
                  color: AppColors.brandTeal,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    point.label,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 8, 6),
            child: OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 6,
              children: [
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Quitar'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onChange,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandTeal.withValues(
                      alpha: 0.12,
                    ),
                    foregroundColor: AppColors.brandTeal,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.edit_location_alt_rounded,
                    size: 16,
                  ),
                  label: const Text('Cambiar ubicación'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mapa sin ubicación fijada: invita a ubicar el pin de llegada.
class _EmptyLocation extends StatelessWidget {
  const _EmptyLocation({required this.onPinTap});

  final VoidCallback onPinTap;

  @override
  Widget build(BuildContext context) {
    return DashedBorderBox(
      backgroundColor: AppColors.surfaceContainerLow,
      strokeWidth: 1.5,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 200),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandTeal.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.brandTeal.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.wrong_location_rounded,
                  size: 26,
                  color: AppColors.brandTeal,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sin ubicación fijada',
                textAlign: TextAlign.center,
                style: AppTypography.headlineSm.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 290),
                child: Text(
                  'Ubica el pin en el mapa para facilitar la llegada de '
                  'tus clientes',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onPinTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandTeal,
                  foregroundColor: AppColors.onPrimary,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.pin_drop_rounded, size: 18),
                label: const Text('Fijar en el mapa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
