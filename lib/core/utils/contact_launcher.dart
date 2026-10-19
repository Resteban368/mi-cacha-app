import 'package:url_launcher/url_launcher.dart';

/// Abre un enlace fuera de la app; `false` si no hay con qué abrirlo.
typedef UrlOpener = Future<bool> Function(Uri uri);

Future<bool> _defaultOpener(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Teléfonos de clientes: normaliza el número y arma los enlaces de WhatsApp
/// y de llamada.
abstract final class ContactLauncher {
  /// Solo dígitos con indicativo de país: `3159012304`, `+57 315 901 2304` y
  /// `573159012304` dan `573159012304`. Un número de 10 dígitos se toma como
  /// colombiano; los que ya traen otro indicativo se dejan como están.
  /// `null` si no parece un teléfono.
  static String? normalize(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.length < 7) return null;
    return digits.length == 10 ? '57$digits' : digits;
  }

  /// Chat de WhatsApp con el cliente, con un texto opcional ya escrito.
  /// WhatsApp no tiene un enlace para iniciar una llamada: la llamada se hace
  /// desde el chat con el ícono del teléfono.
  static Uri? whatsAppChat(String phone, {String? text}) {
    final number = normalize(phone);
    if (number == null) return null;
    final hasText = text != null && text.isNotEmpty;
    return Uri.https('wa.me', '/$number', hasText ? {'text': text} : null);
  }

  /// Marcador del teléfono (llamada normal).
  static Uri? dial(String phone) {
    final number = normalize(phone);
    return number == null ? null : Uri(scheme: 'tel', path: '+$number');
  }

  /// `+57 315 901 2304` para mostrarlo; otros indicativos solo con `+`.
  static String display(String phone) {
    final number = normalize(phone);
    if (number == null) return phone;
    if (number.startsWith('57') && number.length == 12) {
      return '+57 ${number.substring(2, 5)} ${number.substring(5, 8)} '
          '${number.substring(8)}';
    }
    return '+$number';
  }

  /// Abre [uri] sin dejar escapar errores de la plataforma.
  static Future<bool> open(Uri uri, {UrlOpener opener = _defaultOpener}) async {
    try {
      return await opener(uri);
    } catch (_) {
      return false;
    }
  }
}
