import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/theme/app_colors.dart';

/// Capa de teselas del mapa, clara u oscura según la apariencia.
/// [tileProvider] permite reemplazarla en los tests (sin red).
class OsmTileLayer extends StatelessWidget {
  const OsmTileLayer({super.key, this.tileProvider});

  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) => TileLayer(
    urlTemplate: AppColors.isDark ? MapConfig.darkTileUrl : MapConfig.tileUrl,
    fallbackUrl: MapConfig.fallbackUrl,
    subdomains: MapConfig.subdomains,
    retinaMode: RetinaMode.isHighDensity(context),
    userAgentPackageName: MapConfig.userAgentPackageName,
    tileProvider: tileProvider,
  );
}
