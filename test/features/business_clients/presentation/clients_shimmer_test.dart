import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/widgets/shimmer_box.dart';
import 'package:mi_cancha/features/business_clients/presentation/widgets/clients_shimmer.dart';

void main() {
  testWidgets('ClientsShimmer renders TableShimmer on desktop breakpoint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClientsShimmer(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ClientsTableShimmer), findsOneWidget);
    expect(find.byType(ClientsCardListShimmer), findsNothing);
    expect(find.text('JUGADOR / DOCUMENTO'), findsOneWidget);
    expect(find.text('CONTACTO / WHATSAPP'), findsOneWidget);
    expect(find.byType(ShimmerBox), findsWidgets);
  });

  testWidgets('ClientsShimmer renders CardListShimmer on mobile breakpoint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClientsShimmer(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ClientsTableShimmer), findsNothing);
    expect(find.byType(ClientsCardListShimmer), findsOneWidget);
    expect(find.byType(ClientsCardShimmer), findsWidgets);
    expect(find.byType(ShimmerBox), findsWidgets);
  });

  testWidgets('ClientsShimmer explicitly passes isDesktop flag correctly', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ClientsShimmer(isDesktop: false, itemCount: 3),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ClientsCardShimmer), findsNWidgets(3));
  });
}
