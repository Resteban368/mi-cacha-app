import '../location/geo_point.dart';

/// Mapas con teselas raster de Stadia Maps (estilo "Alidade Smooth", limpio
/// como Google Maps, con versión oscura).
///
/// Stadia autoriza en web por dominio (registrado en su panel) y en móvil
/// con `--dart-define=STADIA_API_KEY=...`. Si no responde, se usan las
/// teselas públicas de OpenStreetMap ([fallbackUrl]).
abstract final class MapConfig {
  static const _stadiaKey = String.fromEnvironment('STADIA_API_KEY');
  static const _keyParam = _stadiaKey == '' ? '' : '?api_key=$_stadiaKey';

  /// Teselas claras; `{r}` pide la versión @2x en pantallas densas.
  static const tileUrl =
      'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png'
      '$_keyParam';

  /// Teselas para el modo oscuro.
  static const darkTileUrl =
      'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
      '$_keyParam';

  /// Respaldo sin clave (OpenStreetMap, estilo Humanitario).
  static const fallbackUrl =
      'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';

  /// Subdominios del respaldo.
  static const subdomains = ['a', 'b', 'c'];

  /// Identifica la app ante el servidor de teselas.
  static const userAgentPackageName = 'com.example.mi_cancha';

  static const attribution = '© Stadia Maps © OpenMapTiles © OpenStreetMap';

  /// Centro inicial sin ubicación: Florencia (Caquetá), a nivel de barrios.
  static const defaultCenter = GeoPoint(1.6144, -75.6062);
  static const defaultZoom = 14.0;

  /// Zoom al mostrar un punto ya fijado (nivel de calle).
  static const pointZoom = 17.0;

  /// Desde este zoom se puede confirmar el punto (antes es muy impreciso).
  static const minConfirmZoom = 15.0;
}
