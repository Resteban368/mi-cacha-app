import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/widgets/app_top_bar.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(WidgetTester tester, Widget bar, {bool drawer = true}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: drawer ? const Drawer(child: Text('menú')) : null,
            // La pantalla tiene su propio Scaffold (sin menú), como
            // "Crear Reserva" dentro del panel.
            body: Scaffold(body: Column(children: [bar])),
          ),
        ),
      );

  testWidgets('con "Volver" también ofrece abrir el menú del panel', (
    tester,
  ) async {
    var backs = 0;
    await pump(
      tester,
      AppTopBar(
        title: 'Crear Reserva',
        icon: Icons.event_available,
        onBack: () => backs++,
      ),
    );

    await tester.tap(find.byTooltip('Volver'));
    expect(backs, 1);

    await tester.tap(find.byTooltip('Abrir menú'));
    await tester.pumpAndSettle();
    expect(find.text('menú'), findsOneWidget);
  });

  testWidgets('sin menú muestra la insignia', (tester) async {
    await pump(
      tester,
      const AppTopBar(title: 'Reservas', icon: Icons.event_note),
      drawer: false,
    );
    expect(find.byTooltip('Abrir menú'), findsNothing);
    expect(find.byIcon(Icons.event_note), findsOneWidget);
  });
}
