import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/widgets/shimmer_box.dart';
import 'package:mi_cancha/features/business_reservations/presentation/widgets/create_reservation_shimmer.dart';

void main() {
  testWidgets('CustomerSearchShimmer renders skeleton items with ShimmerBox', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomerSearchShimmer(itemCount: 3),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ShimmerBox), findsWidgets);
    expect(find.byType(CustomerSearchShimmer), findsOneWidget);
  });

  testWidgets(
      'CourtSchedulesShimmer renders court cards and slots grid on wide width',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CourtSchedulesShimmer(courtCount: 2),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CourtSchedulesShimmer), findsOneWidget);
    expect(find.byType(ShimmerBox), findsWidgets);
  });

  testWidgets(
      'CourtSchedulesShimmer renders single column on mobile width',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CourtSchedulesShimmer(courtCount: 2),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CourtSchedulesShimmer), findsOneWidget);
    expect(find.byType(ShimmerBox), findsWidgets);
  });
}
