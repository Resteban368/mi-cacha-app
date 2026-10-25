import '../location/geo_point.dart';

/// Mapas con las teselas estándar de OpenStreetMap: muestran lugares de
/// referencia (iglesias, hospitales, bancos, tiendas, paradas) para guiarse.
///
/// Su política de uso pide identificar la app, mostrar el crédito y no
/// abusar del servidor público; con mucho tráfico conviene Google Maps o un
/// proveedor con clave cambiando solo [tileUrl].
abstract final class MapConfig {
  static const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Respaldo si el principal no responde (OSM estilo Humanitario).
  static const fallbackUrl =
      'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';

  /// Subdominios del respaldo.
  static const subdomains = ['a', 'b', 'c'];

  /// Identifica la app ante el servidor de teselas (OSM bloquea
  /// `com.example`).
  static const userAgentPackageName = 'com.micanchaapp.negocio';

  /// Zoom máximo que entrega OSM (los lugares se ven desde ~16).
  static const maxZoom = 19.0;

  static const attribution = '© OpenStreetMap contributors';

  /// Centro inicial sin ubicación: Florencia (Caquetá), a nivel de barrios.
  static const defaultCenter = GeoPoint(1.6144, -75.6062);
  static const defaultZoom = 14.0;

  /// Zoom al mostrar un punto ya fijado (nivel de calle).
  static const pointZoom = 17.0;

  /// Desde este zoom se puede confirmar el punto (antes es muy impreciso).
  static const minConfirmZoom = 15.0;
}
