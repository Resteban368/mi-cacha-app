import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_home/presentation/navigation/business_section.dart';
import 'package:mi_cancha/features/business_home/presentation/widgets/business_side_menu.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Set<BusinessSection> hidden = const {},
    Map<BusinessSection, int> badges = const {},
  }) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BusinessSideMenu(
            current: BusinessSection.reservas,
            hidden: hidden,
            badges: badges,
            onSelected: (_) {},
            onLogout: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('Inventario muestra el contador de alertas de stock', (
    tester,
  ) async {
    await pump(tester, badges: {BusinessSection.inventario: 3});
    expect(find.text('Inventario'), findsOneWidget);
    expect(find.byKey(const Key('menu-badge-Inventario')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('sin alertas no hay contador', (tester) async {
    await pump(tester, badges: {BusinessSection.inventario: 0});
    expect(find.byKey(const Key('menu-badge-Inventario')), findsNothing);
  });

  testWidgets('sin el módulo se ocultan Ventas e Inventario', (tester) async {
    await pump(
      tester,
      hidden: {BusinessSection.ventas, BusinessSection.inventario},
    );
    expect(find.text('Ventas'), findsNothing);
    expect(find.text('Inventario'), findsNothing);
  });

  test('cada ruta abre su sección', () {
    expect(
      BusinessSection.fromLocation('/negocio/inventario'),
      BusinessSection.inventario,
    );
    expect(
      BusinessSection.fromLocation('/negocio/ventas/productos'),
      BusinessSection.ventas,
    );
  });
}
