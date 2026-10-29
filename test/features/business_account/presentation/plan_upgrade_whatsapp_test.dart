import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_account/presentation/utils/plan_upgrade_whatsapp.dart';

void main() {
  test('abre el WhatsApp de ventas con el negocio y el plan', () {
    final uri = planUpgradeWhatsAppUri('Pro', businessName: 'El Campín');
    expect(uri.host, 'wa.me');
    expect(uri.path, '/573208806654');
    expect(
      uri.queryParameters['text'],
      'Hola, soy el administrador de El Campín y quiero cambiar al plan Pro.',
    );
  });

  test('sin nombre del negocio usa un mensaje genérico', () {
    expect(
      planUpgradeWhatsAppUri('Pro').queryParameters['text'],
      'Hola, quiero cambiar mi negocio al plan Pro.',
    );
  });

  test('pedir el módulo de Ventas e inventario', () {
    final uri = salesModuleRequestWhatsAppUri(businessName: 'El Campín');
    expect(uri.path, '/573208806654');
    expect(
      uri.queryParameters['text'],
      'Hola, soy el administrador de El Campín y quiero activar el módulo de '
      'Ventas e inventario.',
    );
    expect(
      salesModuleRequestWhatsAppUri().queryParameters['text'],
      'Hola, quiero activar el módulo de Ventas e inventario para mi negocio.',
    );
  });

  testWidgets('si no se puede abrir WhatsApp lo avisa', (tester) async {
    Uri? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => openPlanUpgrade(
                context,
                'Pro',
                opener: (uri) async {
                  opened = uri;
                  return false;
                },
              ),
              child: const Text('cambiar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('cambiar'));
    await tester.pumpAndSettle();

    expect(opened?.path, '/573208806654');
    expect(find.textContaining('No pudimos abrir WhatsApp'), findsOneWidget);
  });
}
