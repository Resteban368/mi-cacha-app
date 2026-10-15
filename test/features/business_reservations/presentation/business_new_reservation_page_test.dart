import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/session/write_access.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/availability.dart';
import 'package:mi_cancha/features/business_reservations/presentation/bloc/new_reservation/new_reservation_bloc.dart';
import 'package:mi_cancha/features/business_reservations/presentation/pages/business_new_reservation_page.dart';
import 'package:mocktail/mocktail.dart';

import '../booking_fixtures.dart';

class _MockBloc extends MockBloc<NewReservationEvent, NewReservationState>
    implements NewReservationBloc {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const NewReservationStarted());
  });

  late _MockBloc bloc;
  setUp(() => bloc = _MockBloc());

  final ready = NewReservationState(
    day: DateTime(2026, 10, 15),
    load: NewReservationLoad.ready,
    courts: [court('c1'), court('c0', active: false)],
    paymentMethods: const [efectivo, nequi],
    court: court('c1'),
    availabilityLoad: AvailabilityLoad.ready,
    availability: availability,
    customerSearch: CustomerSearchStatus.ready,
    customerResults: const [laura],
  );
  // 20:00 y 21:00 elegidos.
  final chosen = ready.copyWith(startIndex: () => 5, slotCount: 2);

  Future<void> pump(
    WidgetTester tester,
    NewReservationState state, {
    Size size = const Size(390, 3200),
    Stream<NewReservationState>? stream,
    bool canWrite = true,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    whenListen(
      bloc,
      stream ?? const Stream<NewReservationState>.empty(),
      initialState: state,
    );
    await tester.pumpWidget(
      WriteAccessScope(
        notifier: WriteAccess()..update(canWrite: canWrite),
        child: MaterialApp(
          home: BlocProvider<NewReservationBloc>.value(
            value: bloc,
            child: const BusinessNewReservationPage(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  NewReservationSubmitted submitted() =>
      verify(
            () => bloc.add(captureAny(that: isA<NewReservationSubmitted>())),
          ).captured.single
          as NewReservationSubmitted;

  testWidgets('muestra los turnos con hora y precio', (tester) async {
    await pump(tester, ready);

    expect(find.text('Cancha c1'), findsOneWidget);
    expect(find.text('5 libres'.toUpperCase()), findsOneWidget);
    expect(find.text('4:00 p. m.'), findsOneWidget);
    // El turno de las 8:00 a. m. ya pasó: no se muestra.
    expect(find.text('8:00 a. m.'), findsNothing);
    expect(find.byKey(const Key('slot-0')), findsNothing);
    // El ocupado (7:00 p. m.) se ve, en gris y sin poder elegirse.
    expect(find.text('7:00 p. m.'), findsOneWidget);
    expect(find.text(r'$60.000'), findsWidgets);
    await tester.tap(find.byKey(const Key('slot-1')));
    verify(() => bloc.add(const NewReservationSlotTapped(1))).called(1);
    // Ocupado: no se puede elegir.
    await tester.tap(find.byKey(const Key('slot-4')));
    verifyNever(() => bloc.add(const NewReservationSlotTapped(4)));
  });

  testWidgets('con turno elegido muestra el rango y el subtotal', (
    tester,
  ) async {
    await pump(tester, chosen);
    expect(find.byKey(const Key('selected-range')), findsOneWidget);
    expect(find.text(r'$180.000'), findsWidgets);
    expect(find.text('Falta: cliente'), findsOneWidget);
  });

  testWidgets('cliente existente: confirma con customerId y el inicio exacto', (
    tester,
  ) async {
    await pump(tester, chosen.copyWith(customer: () => laura));
    expect(find.byKey(const Key('reservation-missing')), findsNothing);

    await tester.tap(find.byKey(const Key('confirm-reservation')));
    await tester.pump();

    final r = submitted().reservation;
    expect(r.courtId, 'c1');
    expect(r.start, availability.slots[5].startIso);
    expect(r.slots, 2);
    expect(r.customerId, 'cu1');
    expect(r.customer, isNull);
    expect(r.payment, isNull);
  });

  testWidgets('cliente nuevo con pago en Nequi exige la referencia', (
    tester,
  ) async {
    await pump(tester, chosen);

    await tester.tap(find.text('Cliente nuevo'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('customer-name')), 'Ana Ruiz');
    await tester.enterText(
      find.byKey(const Key('customer-phone')),
      '311 555 0002',
    );
    await tester.enterText(
      find.byKey(const Key('customer-document')),
      '1.075.000.111',
    );
    await tester.enterText(
      find.byKey(const Key('reservation-discount')),
      '20000',
    );
    await tester.tap(find.byKey(const Key('register-payment')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pay-total')));
    await tester.tap(find.text('Nequi'));
    await tester.pump();
    expect(find.text('Falta: referencia del pago'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('payment-reference')),
      'M123456',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-reservation')));
    await tester.pump();

    final r = submitted().reservation;
    expect(r.customerId, isNull);
    expect(r.customer!.name, 'Ana Ruiz');
    expect(r.discount, 20000);
    expect(r.payment!.amount, 160000);
    expect(r.payment!.method, 'NEQUI');
    expect(r.payment!.reference, 'M123456');
  });

  testWidgets('al crear muestra el resumen', (tester) async {
    await pump(
      tester,
      chosen,
      stream: Stream.value(
        chosen.copyWith(
          submit: NewReservationSubmit.success,
          created: () => created,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reserva confirmada'), findsOneWidget);
    expect(find.text(r'$100.000'), findsOneWidget);
    expect(find.text(r'$50.000'), findsNWidgets(2)); // pagado y saldo
    expect(find.text('Confirmada'), findsOneWidget);
  });

  testWidgets('sin canchas reservables lleva a Canchas', (tester) async {
    await pump(
      tester,
      NewReservationState(
        day: DateTime(2026, 10, 15),
        load: NewReservationLoad.ready,
        courts: [court('c0', complete: false)],
      ),
    );
    expect(find.textContaining('No tienes canchas listas'), findsOneWidget);
    expect(find.text('Ir a Canchas'), findsOneWidget);
  });

  testWidgets('en solo lectura no deja crear reservas', (tester) async {
    await pump(tester, ready, canWrite: false);
    expect(find.text('Modo solo lectura'), findsOneWidget);
    expect(find.byKey(const Key('confirm-reservation')), findsNothing);
  });

  for (final size in const [Size(320, 640), Size(1280, 900)]) {
    testWidgets('sin overflow en ${size.width}x${size.height}', (tester) async {
      await pump(tester, chosen.copyWith(customer: () => laura), size: size);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('si ya pasaron todos los turnos lo avisa', (tester) async {
    await pump(
      tester,
      ready.copyWith(
        availability: () => Availability(
          date: '2026-10-15',
          courtId: 'c1',
          slotDuration: 60,
          currency: 'COP',
          maxSlots: 5,
          slots: [
            slotAt(8, status: SlotStatus.past),
            slotAt(9, status: SlotStatus.past),
          ],
        ),
      ),
    );
    expect(
      find.text('Ya pasaron todos los turnos de este día. Elige otra fecha.'),
      findsOneWidget,
    );
  });
}
