/// Configuración de la API. La URL se puede cambiar al compilar:
/// `flutter run --dart-define=API_BASE_URL=https://otra-api/api/v1`.
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mi-cancha-api.vercel.app/api/v1',
  );

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 20);

  /// Marca en `Options.extra` para no adjuntar el token (p. ej. el login).
  static const skipAuth = 'skipAuth';

  /// Fuerza HTTPS en las URL que entrega la API (p. ej. fotos): si el
  /// servidor arma un enlace `http://`, se pide igual por HTTPS.
  static String secureUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'http') return url;
    return uri.replace(scheme: 'https').toString();
  }
}
