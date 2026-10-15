import '../location/geo_point.dart';

/// Mapas con teselas de OpenStreetMap (sin API key).
///
/// Su política de uso pide identificar la app y no abusar del servidor
/// público; con mucho tráfico conviene un proveedor con clave (MapTiler,
/// Stadia) cambiando solo [tileUrl].
abstract final class MapConfig {
  static const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Identifica la app ante el servidor de teselas.
  static const userAgentPackageName = 'com.example.mi_cancha';

  static const attribution = '© OpenStreetMap';

  /// Centro inicial sin ubicación: Florencia (Caquetá), a nivel de barrios.
  static const defaultCenter = GeoPoint(1.6144, -75.6062);
  static const defaultZoom = 14.0;

  /// Zoom al mostrar un punto ya fijado (nivel de calle).
  static const pointZoom = 17.0;

  /// Desde este zoom se puede confirmar el punto (antes es muy impreciso).
  static const minConfirmZoom = 15.0;
}
