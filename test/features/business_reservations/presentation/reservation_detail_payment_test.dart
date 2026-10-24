import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/core/router/app_routes.dart';
import 'package:mi_cancha/core/session/write_access.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';
import 'package:mi_cancha/features/business_reservations/domain/usecases/booking_usecases.dart';
import 'package:mi_cancha/features/business_reservations/presentation/bloc/reservation_detail/reservation_detail_cubit.dart';
import 'package:mi_cancha/features/business_reservations/presentation/widgets/reservation_detail_sheet.dart';
import 'package:mocktail/mocktail.dart';

class _MockGet extends Mock implements GetReservation {}

class _MockCancel extends Mock implements CancelReservation {}

class _MockStatus extends Mock implements UpdateReservationStatus {}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late _MockGet get;

  setUp(() {
    get = _MockGet();
    when(() => get(any())).thenThrow(Exception());
  });

  Reservation reservation({
    required DateTime start,
    int paid = 0,
    ReservationStatus status = ReservationStatus.confirmed,
  }) => Reservation(
    id: 'r1',
    courtName: 'Cancha 1',
    sport: Sport.futbol,
    start: start,
    end: start.add(const Duration(hours: 1)),
    customerName: 'Valderrama',
    phone: '+57 320 922 0378',
    totalPrice: 70000,
    amountPaid: paid,
    status: status,
  );

  /// Abre el detalle sobre un GoRouter real; "Nuevo pago" es una pantalla
  /// falsa que guarda la reserva recibida y vuelve con `true` al pagar.
  Future<List<Object?>> pumpDetail(WidgetTester tester, Reservation r) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final extras = <Object?>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showReservationDetail(
                  context,
                  reservation: r,
                  createCubit: () => ReservationDetailCubit(
                    getReservation: get,
                    cancelReservation: _MockCancel(),
                    updateStatus: _MockStatus(),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.businessNewPayment,
          builder: (context, state) {
            extras.add(state.extra);
            return Scaffold(
              body: TextButton(
                onPressed: () => context.pop(true),
                child: const Text('pagar'),
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      WriteAccessScope(
        notifier: WriteAccess()..update(canWrite: true),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return extras;
  }

  testWidgets('reserva pasada: sin cancelar, con jugada, no asistió y pago', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      reservation(start: DateTime.now().subtract(const Duration(hours: 3))),
    );

    expect(find.byKey(const Key('cancel-reservation')), findsNothing);
    expect(find.byKey(const Key('mark-no-show')), findsOneWidget);
    expect(find.byKey(const Key('mark-completed')), findsOneWidget);
    expect(find.byKey(const Key('register-payment')), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);
  });

  testWidgets('reserva futura: se puede cancelar', (tester) async {
    await pumpDetail(
      tester,
      reservation(start: DateTime.now().add(const Duration(days: 1))),
    );

    expect(find.byKey(const Key('cancel-reservation')), findsOneWidget);
    expect(find.byKey(const Key('register-payment')), findsOneWidget);
  });

  testWidgets('sin saldo pendiente no ofrece pagar', (tester) async {
    await pumpDetail(
      tester,
      reservation(
        start: DateTime.now().subtract(const Duration(hours: 3)),
        paid: 70000,
      ),
    );

    expect(find.byKey(const Key('register-payment')), findsNothing);
  });

  testWidgets('realizar pago abre "Nuevo pago" con la reserva y refresca', (
    tester,
  ) async {
    final past = reservation(
      start: DateTime.now().subtract(const Duration(hours: 3)),
    );
    final extras = await pumpDetail(tester, past);

    await tester.tap(find.byKey(const Key('register-payment')));
    await tester.pumpAndSettle();
    expect(extras, [past]);
    expect(find.text('pagar'), findsOneWidget);

    // Al volver ya pagada, el detalle sigue abierto y trae la reserva al día.
    reset(get);
    when(
      () => get('r1'),
    ).thenAnswer((_) async => reservation(start: past.start, paid: 70000));
    await tester.tap(find.text('pagar'));
    await tester.pumpAndSettle();

    expect(find.text('Pago registrado.'), findsOneWidget);
    verify(() => get('r1')).called(1);
    expect(find.byKey(const Key('register-payment')), findsNothing);
    expect(find.text('Cerrar'), findsOneWidget);
  });
}
