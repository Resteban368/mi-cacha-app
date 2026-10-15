import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/widgets/app_network_image.dart';
import 'package:mi_cancha/core/widgets/shimmer_box.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget image) => tester.pumpWidget(
    MaterialApp(
      home: Center(child: SizedBox(width: 200, height: 120, child: image)),
    ),
  );

  testWidgets('mientras descarga muestra el shimmer', (tester) async {
    await pump(tester, const AppNetworkImage('https://api.test/foto.jpg'));
    expect(find.byType(ShimmerBox), findsOneWidget);
    expect(find.bySemanticsLabel('Cargando imagen'), findsOneWidget);
  });

  testWidgets('si falla quita el shimmer y muestra el error', (tester) async {
    // En los tests toda petición HTTP responde 400: la imagen falla.
    await pump(
      tester,
      const AppNetworkImage(
        'https://api.test/foto.jpg',
        error: Text('sin-foto'),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    expect(find.text('sin-foto'), findsOneWidget);
    expect(find.byType(ShimmerBox), findsNothing);
  });

  testWidgets('con "reducir movimiento" el shimmer queda quieto', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: 100, height: 50, child: ShimmerBox()),
        ),
      ),
    );
    // Sin animaciones pendientes: pumpAndSettle termina.
    await tester.pumpAndSettle();
    expect(find.byType(ShimmerBox), findsOneWidget);
  });
}
