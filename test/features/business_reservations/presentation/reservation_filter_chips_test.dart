import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/day_agenda.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation_filter.dart';
import 'package:mi_cancha/features/business_reservations/presentation/widgets/reservation_filter_chips.dart';

import '../reservation_fixtures.dart';

void main() {
  testWidgets('el chip Canceladas se puede tocar y avisa el filtro', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    ReservationFilter? toggled;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReservationFilterChips(
            agenda: DayAgenda(day: day, now: now, reservations: designScenario),
            selected: null,
            onToggle: (filter) => toggled = filter,
          ),
        ),
      ),
    );

    expect(find.text('Canceladas'), findsOneWidget);
    await tester.tap(find.text('Canceladas'));
    expect(toggled, ReservationFilter.cancelled);
  });
}
