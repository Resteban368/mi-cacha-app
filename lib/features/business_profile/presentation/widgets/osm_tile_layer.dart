import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/theme/app_colors.dart';

/// Capa de teselas de OpenStreetMap; en modo oscuro se invierten los
/// colores. [tileProvider] permite reemplazarla en los tests (sin red).
class OsmTileLayer extends StatelessWidget {
  const OsmTileLayer({super.key, this.tileProvider});

  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) => TileLayer(
    urlTemplate: MapConfig.tileUrl,
    fallbackUrl: MapConfig.fallbackUrl,
    subdomains: MapConfig.subdomains,
    maxNativeZoom: MapConfig.maxZoom.toInt(),
    userAgentPackageName: MapConfig.userAgentPackageName,
    tileBuilder: AppColors.isDark ? darkModeTileBuilder : null,
    tileProvider: tileProvider,
  );
}
