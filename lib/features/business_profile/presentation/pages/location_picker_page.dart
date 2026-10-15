import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
      appBar: AppBar(
        title: const Text('Ubicación de tu sede'),
        backgroundColor: AppColors.surfaceContainerLowest,
        foregroundColor: AppColors.onSurface,
        titleTextStyle: AppTypography.headlineSm.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _latLng(initial.$1),
              initialZoom: initial.$2,
              minZoom: 3,
              maxZoom: 19,
              // Tocar un punto lo lleva al centro (bajo el pin).
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
          // Pin fijo en el centro: la punta marca el punto elegido.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 44),
                child: Icon(
                  Icons.location_on,
                  key: Key('location-pin'),
                  size: 48,
                  color: AppColors.statusDue,
                  shadows: [Shadow(color: Color(0x55000000), blurRadius: 6)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 72,
            child: Align(
              alignment: Alignment.topLeft,
              child: _Hint(
                text:
                    'Mueve el mapa hasta dejar el pin en la entrada de tu '
                    'sede.',
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.add,
                  tooltip: 'Acercar',
                  onPressed: () => _zoom(1),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  icon: Icons.remove,
                  tooltip: 'Alejar',
                  onPressed: () => _zoom(-1),
                ),
                const SizedBox(height: 8),
                _MapButton(
                  key: const Key('use-my-location'),
                  icon: Icons.my_location,
                  tooltip: 'Usar mi ubicación actual',
                  busy: _locating,
                  onPressed: _locating ? null : _useCurrentLocation,
                ),
              ],
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

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.busy = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: AppColors.brandTeal,
        icon: busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brandTeal,
                ),
              )
            : Icon(icon),
      ),
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Color(0x1417231C),
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
                  Text(
                    hint ?? 'Punto de llegada: ${point.label}',
                    key: const Key('location-coordinates'),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const Key('confirm-location'),
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor:
                          AppColors.surfaceContainerHighest,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: AppTypography.labelLg.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
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
