import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/core/session/write_access.dart';
import 'package:mi_cancha/core/widgets/app_network_image.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/availability.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/new_reservation.dart';
import 'package:mi_cancha/features/business_reservations/presentation/bloc/new_reservation/new_reservation_bloc.dart';
import 'package:mi_cancha/features/business_reservations/presentation/pages/business_new_reservation_page.dart';
import 'package:mi_cancha/features/business_reservations/presentation/widgets/create_reservation_shimmer.dart';
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
    courts: [
      court('c1'),
      court('c2'),
      court('c0', active: false),
      court('p1', sport: Sport.padel),
    ],
    paymentMethods: const [efectivo, nequi],
    sport: Sport.futbol,
    availabilityLoad: AvailabilityLoad.ready,
    availability: availability,
    customerSearch: CustomerSearchStatus.ready,
    customerResults: const [laura],
  );
  // 20:00 y 21:00 de la cancha c1 elegidos.
  final chosen = ready.copyWith(
    selectedCourtId: () => 'c1',
    selectedStart: () => at(20),
    slotCount: 2,
  );

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

  testWidgets('una tarjeta por cancha con foto, tipo, libres y turnos', (
    tester,
  ) async {
    await pump(tester, ready);

    // Deportes con canchas: fútbol (elegido) y pádel.
    expect(find.byKey(const Key('sport-FUTBOL')), findsOneWidget);
    expect(find.byKey(const Key('sport-PADEL')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sport-PADEL')));
    verify(
      () => bloc.add(const NewReservationSportSelected(Sport.padel)),
    ).called(1);

    expect(find.text('CANCHA C1'), findsOneWidget);
    expect(find.text('CANCHA C2'), findsOneWidget);
    expect(find.text('Fútbol · Al aire libre · Turnos de 1 h'), findsOneWidget);
    expect(find.text('Fútbol · Cubierta · Turnos de 1 h'), findsOneWidget);
    expect(find.text('5 Libres'), findsOneWidget);
    expect(find.text('4 Libres'), findsOneWidget);
    expect(find.byType(AppNetworkImage), findsNWidgets(2));
    // La inactiva no aparece; se avisa con acceso a Canchas.
    expect(find.text('CANCHA C0'), findsNothing);
    expect(find.byKey(const Key('hidden-courts')), findsOneWidget);

    // El turno de las 8:00 a. m. ya pasó: no se muestra.
    expect(find.text('8:00 a. m.'), findsNothing);
    expect(find.byKey(const Key('slot-c1-0')), findsNothing);
    expect(find.text(r'$60.000'), findsWidgets);
    await tester.tap(find.byKey(const Key('slot-c1-1')));
    verify(
      () => bloc.add(NewReservationSlotTapped(courtId: 'c1', start: at(16))),
    ).called(1);
    await tester.tap(find.byKey(const Key('slot-c2-2')));
    verify(
      () => bloc.add(NewReservationSlotTapped(courtId: 'c2', start: at(18))),
    ).called(1);
    // Ocupado (19:00 en c1): se ve en gris y no se puede elegir.
    await tester.tap(find.byKey(const Key('slot-c1-4')));
    verifyNever(
      () => bloc.add(NewReservationSlotTapped(courtId: 'c1', start: at(19))),
    );
  });

  testWidgets('cualquier cancha: una sola grilla de horarios', (tester) async {
    await pump(tester, ready);
    await tester.tap(find.byKey(const Key('any-court')));
    verify(() => bloc.add(const NewReservationAnyCourtToggled(true))).called(1);
  });

  testWidgets(
    'cualquier cancha: horarios unidos con "desde" y cancha a asignar',
    (tester) async {
      await pump(
        tester,
        ready.copyWith(
          anyCourt: true,
          selectedStart: () => at(17),
          slotCount: 2,
        ),
      );
      expect(find.text('Cancha c1'), findsNothing);
      // 17:00 libre en las dos canchas: el precio más bajo.
      expect(find.text(r'desde $50.000'), findsWidgets);
      // 7:00 p. m. solo libre en c2.
      await tester.tap(find.byKey(const Key('any-slot-4')));
      verify(() => bloc.add(NewReservationSlotTapped(start: at(19)))).called(1);
      expect(
        find.text(
          'Se asignará Cancha c1 si sigue libre; el valor puede cambiar '
          'según la cancha.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('price-may-vary')), findsOneWidget);
      expect(find.textContaining('Cualquier cancha de fútbol'), findsWidgets);
    },
  );

  testWidgets('cualquier cancha: confirma con sport', (tester) async {
    await pump(
      tester,
      ready.copyWith(
        anyCourt: true,
        selectedStart: () => at(17),
        slotCount: 3,
        customer: () => laura,
      ),
    );
    await tester.tap(find.byKey(const Key('confirm-reservation')));
    await tester.pump();

    final r = submitted().reservation;
    expect(r.target, const AnyCourtOfSport(Sport.futbol));
    expect(r.start, c2Slots.slots[1].startIso);
    expect(r.slots, 3);
  });

  testWidgets('deporte sin canchas reservables', (tester) async {
    await pump(
      tester,
      ready.copyWith(
        availability: () => SportAvailability(
          date: '2026-10-15',
          sport: Sport.futbol,
          maxSlots: 5,
          courts: const [],
        ),
      ),
    );
    expect(find.text('No hay canchas de fútbol disponibles.'), findsOneWidget);
    expect(find.byKey(const Key('any-court')), findsNothing);
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
    expect(r.target, const CourtById('c1'));
    expect(r.start, c1Slots.slots[5].startIso);
    expect(r.slots, 2);
    expect(r.customerId, 'cu1');
    expect(r.customer, isNull);
    expect(r.payment, isNull);
  });

  testWidgets('cliente nuevo con pago en Nequi: la referencia es opcional', (
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
    // Sin referencia ya se puede confirmar.
    expect(find.byKey(const Key('reservation-missing')), findsNothing);

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

    expect(find.text('¡Reserva confirmada!'), findsOneWidget);
    // Con la cancha elegida no se destaca la asignación.
    expect(find.byKey(const Key('assigned-court')), findsNothing);
    Finder inDialog(String text) =>
        find.descendant(of: find.byType(Dialog), matching: find.text(text));
    expect(inDialog(r'$100.000'), findsOneWidget);
    expect(inDialog(r'$50.000'), findsNWidgets(2)); // pagado y saldo
    expect(find.text('Confirmada'), findsOneWidget);
  });

  testWidgets('cualquier cancha: el resumen dice en qué cancha quedó', (
    tester,
  ) async {
    final any = ready.copyWith(
      anyCourt: true,
      selectedStart: () => at(16),
      customer: () => laura,
    );
    await pump(
      tester,
      any,
      stream: Stream.value(
        any.copyWith(
          submit: NewReservationSubmit.success,
          created: () => created,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reserva creada en Cancha c1'), findsOneWidget);
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
        availability: () => SportAvailability(
          date: '2026-10-15',
          sport: Sport.futbol,
          maxSlots: 5,
          courts: [
            CourtSlots(
              court: availabilityCourt('c1'),
              availableCount: 0,
              slots: [
                slotAt(8, status: SlotStatus.past),
                slotAt(9, status: SlotStatus.past),
              ],
            ),
          ],
        ),
      ),
    );
    expect(
      find.text('Ya pasaron todos los turnos de este día. Elige otra fecha.'),
      findsOneWidget,
    );
  });

  testWidgets('en web las canchas van en dos columnas', (tester) async {
    await pump(tester, ready, size: const Size(1800, 2400));
    final c1 = tester.getTopLeft(find.text('CANCHA C1'));
    final c2 = tester.getTopLeft(find.text('CANCHA C2'));
    expect(c1.dy, c2.dy);
    expect(c2.dx, greaterThan(c1.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('en web "Confirmar" queda fijo al desplazar los turnos', (
    tester,
  ) async {
    await pump(tester, chosen, size: const Size(1440, 700));
    final confirm = find.byKey(const Key('confirm-reservation'));
    final before = tester.getTopLeft(confirm);

    await tester.drag(
      find.byKey(const Key('reservation-main-scroll')),
      const Offset(0, -600),
    );
    await tester.pump();

    expect(tester.getTopLeft(confirm), before);
    // El cliente está en la columna derecha, a la vista sin desplazar.
    expect(
      tester.getTopLeft(find.byKey(const Key('customer-search'))).dx,
      greaterThan(tester.getTopLeft(find.byKey(const Key('sport-FUTBOL'))).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Enter en la búsqueda elige el primer cliente', (tester) async {
    await pump(tester, chosen);
    await tester.enterText(find.byKey(const Key('customer-search')), 'lau');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    verify(
      () => bloc.add(const NewReservationCustomerSelected(laura)),
    ).called(1);
  });

  testWidgets('mientras busca mantiene los resultados anteriores', (
    tester,
  ) async {
    await pump(
      tester,
      chosen.copyWith(customerSearch: CustomerSearchStatus.loading),
    );
    expect(find.text('Laura Gómez'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('muestra shimmers al cargar turnos o clientes', (tester) async {
    await pump(
      tester,
      ready.copyWith(
        availabilityLoad: AvailabilityLoad.loading,
        customerSearch: CustomerSearchStatus.loading,
        customerResults: const [],
      ),
    );
    expect(find.byType(CourtSchedulesShimmer), findsOneWidget);
    expect(find.byType(CustomerSearchShimmer), findsOneWidget);
  });

  testWidgets('en web: resumen del turno con cliente, pago y botón lima', (
    tester,
  ) async {
    await pump(
      tester,
      chosen.copyWith(customer: () => laura),
      size: const Size(1440, 1200),
    );
    expect(find.text('RESUMEN DEL TURNO'), findsOneWidget);
    expect(find.text('Fútbol · Cancha c1'), findsOneWidget);
    expect(find.text('Laura Gómez (3115550001)'), findsOneWidget);
    expect(find.text('Sin abono'), findsOneWidget);
    expect(find.text('Confirmar e ingresar reserva'), findsOneWidget);
    // El elegido queda marcado en la lista de clientes.
    expect(find.text('Laura Gómez'), findsOneWidget);
    expect(find.text('Elegido (8:00 p. m.)'), findsOneWidget);
  });

  testWidgets('las etiquetas rápidas llenan el campo', (tester) async {
    await pump(tester, chosen.copyWith(customer: () => laura));
    await tester.ensureVisible(find.byKey(const Key('quick-tag-Cumpleaños')));
    await tester.tap(find.byKey(const Key('quick-tag-Cumpleaños')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-reservation')));
    await tester.pump();
    expect(submitted().reservation.tag, 'Cumpleaños');
  });

  testWidgets('la tira de días elige otro día', (tester) async {
    await pump(tester, ready);
    await tester.tap(find.text('17'));
    verify(
      () => bloc.add(NewReservationDaySelected(DateTime(2026, 10, 17))),
    ).called(1);
  });

  testWidgets('en web con poca altura el resumen se compacta', (tester) async {
    await pump(
      tester,
      chosen.copyWith(customer: () => laura),
      size: const Size(1440, 700),
    );
    // Quedan el total y el botón; los detalles no tapan la columna.
    expect(find.text('RESUMEN DEL TURNO'), findsOneWidget);
    expect(find.text('Cliente titular'), findsNothing);
    expect(find.byKey(const Key('confirm-reservation')), findsOneWidget);
    final panel = tester.getRect(
      find.byKey(const Key('reservation-confirm-panel')),
    );
    expect(panel.height, lessThan(240));
    // El cliente y el pago siguen visibles arriba del resumen.
    expect(
      tester.getRect(find.byKey(const Key('customer-search'))).bottom,
      lessThan(panel.top),
    );
    expect(tester.takeException(), isNull);
  });
}
