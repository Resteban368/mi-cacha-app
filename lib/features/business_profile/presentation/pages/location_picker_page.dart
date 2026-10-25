import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../../core/config/map_config.dart';
import '../../../../core/location/device_location.dart';
import '../../../../core/location/geo_point.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/osm_attribution.dart';
import '../widgets/osm_tile_layer.dart';

/// Pantalla para fijar el punto de llegada de la sede: el pin queda en el
/// centro y se mueve el mapa (o se toca un punto) hasta dejarlo en la
/// entrada. Devuelve el [GeoPoint] confirmado, o `null` si se cerró.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({
    super.key,
    required this.deviceLocation,
    this.initial,
    this.tileProvider,
  });

  final DeviceLocation deviceLocation;
  final GeoPoint? initial;

  /// Solo para tests (teselas sin red).
  final TileProvider? tileProvider;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final _map = MapController();
  late final _center = ValueNotifier<(GeoPoint, double)>((
    widget.initial ?? MapConfig.defaultCenter,
    widget.initial == null ? MapConfig.defaultZoom : MapConfig.pointZoom,
  ));
  var _locating = false;

  @override
  void dispose() {
    _center.dispose();
    _map.dispose();
    super.dispose();
  }

  static LatLng _latLng(GeoPoint p) => LatLng(p.latitude, p.longitude);

  void _moveTo(GeoPoint point, double zoom) {
    _map.move(_latLng(point), zoom);
    _center.value = (point, zoom);
  }

  void _zoom(double delta) {
    final camera = _map.camera;
    _map.move(camera.center, (camera.zoom + delta).clamp(3, 19));
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final point = await widget.deviceLocation.current();
      if (!mounted) return;
      _moveTo(point, MapConfig.pointZoom + 1);
    } on DeviceLocationException catch (error) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (error.error) {
            DeviceLocationError.serviceDisabled =>
              'Activa la ubicación del dispositivo e intenta de nuevo.',
            DeviceLocationError.denied =>
              'Necesitamos permiso de ubicación para centrar el mapa.',
            DeviceLocationError.deniedForever =>
              'El permiso de ubicación está bloqueado. Actívalo en los '
                  'ajustes.',
            DeviceLocationError.unavailable =>
              'No pudimos obtener tu ubicación. Mueve el mapa a mano.',
          }),
          backgroundColor: AppColors.statusDue,
          action: error.error == DeviceLocationError.deniedForever
              ? SnackBarAction(
                  label: 'Ajustes',
                  textColor: AppColors.onPrimary,
                  onPressed: widget.deviceLocation.openSettings,
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = _center.value;
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Ubicación de tu sede'),
        elevation: 0,
        backgroundColor: AppColors.surfaceContainerLowest,
        foregroundColor: AppColors.onSurface,
        titleTextStyle: AppTypography.headlineSm.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Mapa interactivo
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _latLng(initial.$1),
              initialZoom: initial.$2,
              minZoom: 3,
              maxZoom: 19,
              onTap: (_, point) => _map.move(point, _map.camera.zoom),
              onPositionChanged: (camera, _) => _center.value = (
                GeoPoint(camera.center.latitude, camera.center.longitude),
                camera.zoom,
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              OsmTileLayer(tileProvider: widget.tileProvider),
              const OsmAttribution(),
            ],
          ),

          // Marcador deportivo central con target reticle y sombra
          const IgnorePointer(
            child: Center(
              child: _VenueTargetPin(),
            ),
          ),

          // Tarjeta flotante superior con instrucciones
          Positioned(
            top: 12,
            left: 12,
            right: 74,
            child: ValueListenableBuilder(
              valueListenable: _center,
              builder: (context, value, _) {
                final zoom = value.$2;
                final isPrecise = zoom >= MapConfig.minConfirmZoom;
                return _ModernMapHeaderCard(isPrecise: isPrecise);
              },
            ),
          ),

          // HUD flotante con controles de Zoom y GPS
          Positioned(
            top: 12,
            right: 12,
            child: _ModernMapControls(
              onZoomIn: () => _zoom(1),
              onZoomOut: () => _zoom(-1),
              onMyLocation: _locating ? null : _useCurrentLocation,
              isLocating: _locating,
            ),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: _center,
        builder: (context, value, _) {
          final (point, zoom) = value;
          final closeEnough = zoom >= MapConfig.minConfirmZoom;
          return _ConfirmBar(
            point: point,
            hint: closeEnough
                ? null
                : 'Acércate más al mapa para ubicar el punto exacto.',
            onConfirm: closeEnough
                ? () => Navigator.of(context).pop(point)
                : null,
          );
        },
      ),
    );
  }
}

/// Pin deportivo central con target reticle concéntrico y sombra de precisión.
class _VenueTargetPin extends StatelessWidget {
  const _VenueTargetPin();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anillo radar exterior
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandTeal.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.brandTeal.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
          ),
          // Anillo radar interior
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandTeal.withValues(alpha: 0.2),
              border: Border.all(
                color: AppColors.brandTeal.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
          ),

          // Sombra en el suelo en el centro exacto
          Positioned(
            top: 50,
            child: Container(
              width: 10,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0x66000000),
                borderRadius: BorderRadius.all(Radius.elliptical(10, 5)),
              ),
            ),
          ),

          // Pin moderno posicionado con su punta exactamente en el centro (y = 50)
          Positioned(
            top: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.brandTeal,
                        AppColors.primary,
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on,
                    key: Key('location-pin'),
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                // Punta del pin
                CustomPaint(
                  size: const Size(8, 6),
                  painter: _PinTipPainter(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PinTipPainter extends CustomPainter {
  const _PinTipPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTipPainter oldDelegate) =>
      color != oldDelegate.color;
}

/// Tarjeta flotante superior moderna
class _ModernMapHeaderCard extends StatelessWidget {
  const _ModernMapHeaderCard({required this.isPrecise});

  final bool isPrecise;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.brandTeal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pin_drop_rounded,
              size: 18,
              color: AppColors.brandTeal,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mueve el mapa hasta dejar el pin en la entrada de tu sede.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPrecise
                          ? Icons.check_circle_rounded
                          : Icons.zoom_in_rounded,
                      size: 13,
                      color: isPrecise
                          ? AppColors.primary
                          : const Color(0xFFE67E22),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        isPrecise ? 'Precisión óptima' : 'Acércate más',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSm.copyWith(
                          fontSize: 10.5,
                          color: isPrecise
                              ? AppColors.primary
                              : const Color(0xFFD35400),
                          fontWeight: FontWeight.w700,
                        ),
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

/// Panel de control lateral para mapa (Zoom y GPS)
class _ModernMapControls extends StatelessWidget {
  const _ModernMapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
    required this.isLocating,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback? onMyLocation;
  final bool isLocating;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ControlIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Acercar',
            onPressed: onZoomIn,
          ),
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
          _ControlIconButton(
            icon: Icons.remove_rounded,
            tooltip: 'Alejar',
            onPressed: onZoomOut,
          ),
          Divider(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
          _ControlIconButton(
            key: const Key('use-my-location'),
            icon: Icons.my_location_rounded,
            tooltip: 'Usar mi ubicación actual',
            iconColor: AppColors.brandTeal,
            busy: isLocating,
            onPressed: onMyLocation,
          ),
        ],
      ),
    );
  }
}

class _ControlIconButton extends StatelessWidget {
  const _ControlIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
    this.busy = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      color: iconColor ?? AppColors.onSurfaceVariant,
      icon: busy
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.brandTeal,
              ),
            )
          : Icon(icon),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.point,
    required this.hint,
    required this.onConfirm,
  });

  final GeoPoint point;
  final String? hint;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final hasError = hint != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: hasError
                          ? AppColors.warningTint
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasError
                            ? AppColors.warningBorder
                            : AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasError
                              ? Icons.info_outline_rounded
                              : Icons.place_rounded,
                          size: 16,
                          color: hasError
                              ? const Color(0xFFD35400)
                              : AppColors.brandTeal,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            hint ?? 'Punto de llegada: ${point.label}',
                            key: const Key('location-coordinates'),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySm.copyWith(
                              color: hasError
                                  ? AppColors.warningInk
                                  : AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    key: const Key('confirm-location'),
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor:
                          AppColors.surfaceContainerHighest,
                      disabledForegroundColor: AppColors.outline,
                      minimumSize: const Size.fromHeight(50),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: AppTypography.labelLg.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 19),
                    label: const Text('Confirmar ubicación'),
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
