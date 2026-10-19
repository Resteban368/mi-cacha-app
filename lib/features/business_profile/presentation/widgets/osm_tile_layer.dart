import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/config/map_config.dart';

/// Capa de teselas de OpenStreetMap. [tileProvider] permite reemplazarla en
/// los tests (sin red).
class OsmTileLayer extends StatelessWidget {
  const OsmTileLayer({super.key, this.tileProvider});

  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) => TileLayer(
    urlTemplate: MapConfig.tileUrl,
    subdomains: MapConfig.subdomains,
    userAgentPackageName: MapConfig.userAgentPackageName,
    tileProvider: tileProvider,
  );
}
