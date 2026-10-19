import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/utils/contact_launcher.dart';

void main() {
  group('normalize', () {
    test('agrega el indicativo de Colombia a un celular de 10 dígitos', () {
      expect(ContactLauncher.normalize('3159012304'), '573159012304');
      expect(ContactLauncher.normalize('315 901 2304'), '573159012304');
    });

    test('respeta el indicativo que ya trae, con o sin + o 00', () {
      expect(ContactLauncher.normalize('+573159012304'), '573159012304');
      expect(ContactLauncher.normalize('573159012304'), '573159012304');
      expect(ContactLauncher.normalize('00573159012304'), '573159012304');
      expect(ContactLauncher.normalize('+1 305 555 0123'), '13055550123');
    });

    test('un texto sin teléfono válido da null', () {
      expect(ContactLauncher.normalize(''), isNull);
      expect(ContactLauncher.normalize('sin teléfono'), isNull);
      expect(ContactLauncher.normalize('12345'), isNull);
    });
  });

  group('enlaces', () {
    test('chat de WhatsApp con el texto codificado', () {
      final uri = ContactLauncher.whatsAppChat(
        '+573159012304',
        text: 'Hola Mateo, tu reserva & más',
      )!;
      expect(uri.host, 'wa.me');
      expect(uri.path, '/573159012304');
      expect(uri.queryParameters['text'], 'Hola Mateo, tu reserva & más');
      expect(uri.toString(), startsWith('https://wa.me/573159012304?text='));
    });

    test('sin texto no agrega el parámetro', () {
      expect(
        ContactLauncher.whatsAppChat('3159012304').toString(),
        'https://wa.me/573159012304',
      );
    });

    test('llamada normal con tel: y el +', () {
      expect(
        ContactLauncher.dial('3159012304').toString(),
        'tel:+573159012304',
      );
    });

    test('sin teléfono válido no hay enlaces', () {
      expect(ContactLauncher.whatsAppChat('abc'), isNull);
      expect(ContactLauncher.dial(''), isNull);
    });
  });

  test('display agrupa los números colombianos', () {
    expect(ContactLauncher.display('3159012304'), '+57 315 901 2304');
    expect(ContactLauncher.display('+1 305 555 0123'), '+13055550123');
    expect(ContactLauncher.display('nada'), 'nada');
  });

  group('open', () {
    final uri = Uri.parse('https://wa.me/573159012304');

    test('devuelve lo que responde el sistema', () async {
      expect(
        await ContactLauncher.open(uri, opener: (_) async => true),
        isTrue,
      );
      expect(
        await ContactLauncher.open(uri, opener: (_) async => false),
        isFalse,
      );
    });

    test('un error de la plataforma no se propaga', () async {
      expect(
        await ContactLauncher.open(uri, opener: (_) => throw StateError('x')),
        isFalse,
      );
    });
  });
}
