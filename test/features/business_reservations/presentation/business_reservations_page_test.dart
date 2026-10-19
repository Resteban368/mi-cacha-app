import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation_filter.dart';
import 'package:mi_cancha/features/business_reservations/presentation/bloc/business_reservations_bloc.dart';
import 'package:mi_cancha/features/business_reservations/presentation/pages/business_reservations_page.dart';
import 'package:mi_cancha/features/business_reservations/presentation/widgets/live_reservation_card.dart';
import 'package:mi_cancha/features/business_reservations/presentation/widgets/reservation_card.dart';
import 'package:mi_cancha/core/session/write_access.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court_schedule.dart';
import 'package:mi_cancha/features/business_reservations/domain/usecases/booking_usecases.dart';
import 'package:mi_cancha/features/business_reservations/presentation/bloc/reservation_detail/reservation_detail_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../reservation_fixtures.dart';

class _MockGet extends Mock implements GetReservation {}

class _MockCancel extends Mock implements CancelReservation {}

class _MockStatus extends Mock implements UpdateReservationStatus {}

class _MockBloc
    extends MockBloc<BusinessReservationsEvent, BusinessReservationsState>
    implements BusinessReservationsBloc {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const ReservationsRefreshed());
  });

  late _MockBloc bloc;
  setUp(() => bloc = _MockBloc());

  BusinessReservationsState loaded({
    ReservationFilter? filter,
    List<Court> courts = const [],
  }) => BusinessReservationsState(
    day: day,
    now: now,
    status: ReservationsStatus.success,
    reservations: designScenario,
    filter: filter,
    courts: courts,
  );

  Future<void> pumpPage(
    WidgetTester tester,
    BusinessReservationsState state, {
    Size size = const Size(390, 2400),
    ReservationDetailCubit Function()? createDetailCubit,
    bool canWrite = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => bloc.state).thenReturn(state);
    await tester.pumpWidget(
      WriteAccessScope(
        notifier: WriteAccess()..update(canWrite: canWrite),
        child: MaterialApp(
          home: Scaffold(
            body: BlocProvider<BusinessReservationsBloc>.value(
              value: bloc,
              child: BusinessReservationsPage(
                createDetailCubit: createDetailCubit,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('hoy sin filtro: secciones, marcador "Ahora" y en juego', (
    tester,
  ) async {
    await pumpPage(tester, loaded());

    expect(find.text('Reservas'), findsOneWidget);
    expect(find.text('Agenda de tus canchas'), findsOneWidget);
    expect(find.byTooltip('Notificaciones'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Viernes, 9 de octubre de 2026'), findsOneWidget);
    expect(find.text('PASADAS'), findsOneWidget);
    expect(find.text('Ahora · 7:15 p. m.'), findsOneWidget);
    expect(find.text('PRÓXIMAS PARA ESTA NOCHE'), findsOneWidget);
    expect(find.byType(LiveReservationCard), findsOneWidget);
    expect(find.text('EN JUEGO'), findsOneWidget);
    expect(find.text('Valentina Dussán'), findsOneWidget);
    expect(find.byType(ReservationCard), findsNWidgets(4));
    expect(find.byTooltip('Nueva reserva'), findsOneWidget);
    // Acceso al listado de todas las reservas.
    expect(find.text('Ver todas las reservas'), findsOneWidget);
  });

  testWidgets('muestra estados y acciones de cobro', (tester) async {
    await pumpPage(tester, loaded());

    expect(find.text('Completada'), findsOneWidget);
    expect(find.text('No asistió'), findsWidgets); // chip + píldora
    expect(find.text('Confirmada'), findsOneWidget);
    expect(find.text('Cobrar en taquilla'), findsOneWidget);
    expect(find.text('Cobrar saldo'), findsOneWidget);
    expect(find.text(r'Saldo: $60.000 COP'), findsOneWidget);
  });

  testWidgets('tocar un filtro lo envía al bloc', (tester) async {
    await pumpPage(tester, loaded());

    await tester.tap(find.text('Próximas'));
    verify(
      () =>
          bloc.add(const ReservationsFilterToggled(ReservationFilter.upcoming)),
    ).called(1);
  });

  testWidgets('con filtro activo muestra lista plana sin secciones', (
    tester,
  ) async {
    await pumpPage(tester, loaded(filter: ReservationFilter.upcoming));

    expect(find.text('PASADAS'), findsNothing);
    expect(find.textContaining('Ahora ·'), findsNothing);
    expect(find.byType(ReservationCard), findsNWidgets(2));
  });

  testWidgets('por cancha muestra la ocupación del día con su barra', (
    tester,
  ) async {
    final court = Court(
      id: 'live',
      name: 'Cancha live',
      sport: Sport.futbol,
      isActive: true,
      isComplete: true,
      isBookable: true,
      schedules: DaySchedule.defaultWeek(),
    );
    final empty = Court(
      id: 'vacia',
      name: 'Cancha vacía',
      sport: Sport.futbol,
      isActive: true,
      isComplete: true,
      isBookable: true,
      schedules: DaySchedule.defaultWeek(),
    );
    await pumpPage(tester, loaded(courts: [court, empty]));
    await tester.tap(find.text('Por cancha'));
    await tester.pump();

    expect(find.byKey(const Key('occupancy-Cancha live')), findsOneWidget);
    // Las canchas sin reservas no se muestran.
    expect(find.text('Cancha vacía'), findsNothing);
    expect(find.byKey(const Key('occupancy-Cancha vacía')), findsNothing);
  });

  testWidgets('con un filtro activo no hay barras de ocupación', (
    tester,
  ) async {
    final court = Court(
      id: 'live',
      name: 'Cancha live',
      sport: Sport.futbol,
      isActive: true,
      isComplete: true,
      isBookable: true,
      schedules: DaySchedule.defaultWeek(),
    );
    await pumpPage(
      tester,
      loaded(filter: ReservationFilter.upcoming, courts: [court]),
    );
    await tester.tap(find.text('Por cancha'));
    await tester.pump();
    expect(find.byKey(const Key('occupancy-Cancha live')), findsNothing);
  });

  testWidgets('vista por cancha agrupa las reservas con su encabezado', (
    tester,
  ) async {
    await pumpPage(tester, loaded());
    await tester.tap(find.text('Por cancha'));
    await tester.pump();

    final listed = loaded().agenda.reservations;
    final courts = {for (final r in listed) r.courtName};
    for (final court in courts) {
      final count = listed.where((r) => r.courtName == court).length;
      expect(find.text(court), findsWidgets);
      expect(
        find.text(count == 1 ? '1 reserva' : '$count reservas'),
        findsWidgets,
      );
    }
    // Sin las secciones de la línea de tiempo.
    expect(find.text('PASADAS'), findsNothing);
    expect(find.textContaining('Ahora ·'), findsNothing);

    await tester.tap(find.text('Por hora'));
    await tester.pump();
    expect(find.text('PASADAS'), findsOneWidget);
  });

  testWidgets('estado de error con reintento', (tester) async {
    await pumpPage(
      tester,
      BusinessReservationsState(
        day: day,
        now: now,
        status: ReservationsStatus.failure,
      ),
    );

    expect(find.text('No pudimos cargar las reservas'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    verify(() => bloc.add(ReservationsRequested(day))).called(1);
  });

  testWidgets('día sin reservas', (tester) async {
    await pumpPage(
      tester,
      BusinessReservationsState(
        day: day,
        now: now,
        status: ReservationsStatus.success,
      ),
    );

    expect(find.text('Sin reservas para este día'), findsOneWidget);
  });

  for (final size in const [Size(320, 568), Size(360, 740), Size(412, 915)]) {
    testWidgets('sin overflow en ${size.width}x${size.height}', (tester) async {
      await pumpPage(tester, loaded(), size: size);
      // Recorrer todo el listado para construir todas las tarjetas.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  group('web / pantallas anchas', () {
    double cardWidth(WidgetTester tester) =>
        tester.getSize(find.byType(ReservationCard).first).width;

    testWidgets('móvil: una columna a todo el ancho', (tester) async {
      await pumpPage(tester, loaded(), size: const Size(390, 2400));
      expect(cardWidth(tester), 390 - 2 * 12);
    });

    testWidgets('tablet: tarjetas en 2 columnas', (tester) async {
      await pumpPage(tester, loaded(), size: const Size(900, 1600));
      expect(cardWidth(tester), (900 - 2 * 24 - 12) / 2);
    });

    testWidgets('escritorio: tarjetas en 3 columnas', (tester) async {
      await pumpPage(tester, loaded(), size: const Size(1400, 1200));
      expect(cardWidth(tester), (1400 - 2 * 24 - 2 * 12) / 3);
      // Las secciones y el marcador "Ahora" se mantienen.
      expect(find.text('PASADAS'), findsOneWidget);
      expect(find.text('Ahora · 7:15 p. m.'), findsOneWidget);
      expect(find.byType(LiveReservationCard), findsOneWidget);
    });

    for (final size in const [
      Size(760, 900),
      Size(1024, 768),
      Size(1920, 1080),
    ]) {
      testWidgets('sin overflow en ${size.width}x${size.height}', (
        tester,
      ) async {
        await pumpPage(tester, loaded(), size: size);
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -3000),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('detalle', () {
    late _MockGet get;
    late _MockCancel cancel;
    late _MockStatus status;

    setUpAll(() {
      registerFallbackValue((id: 'x', reason: 'x'));
      registerFallbackValue((id: 'x', status: ReservationStatus.confirmed));
    });

    setUp(() {
      get = _MockGet();
      cancel = _MockCancel();
      status = _MockStatus();
      // Sin detalle extra: se queda con los datos de la agenda.
      when(() => get(any())).thenThrow(Exception());
    });

    // La tarjeta "en juego" late sin parar: no se usa pumpAndSettle.
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    ReservationDetailCubit cubit() => ReservationDetailCubit(
      getReservation: get,
      cancelReservation: cancel,
      updateStatus: status,
    );

    testWidgets('tocar una reserva abre el detalle y permite cancelarla', (
      tester,
    ) async {
      final live = designScenario.firstWhere((r) => r.id == 'live');
      when(() => cancel(any())).thenAnswer(
        (_) async => Reservation(
          id: live.id,
          courtName: live.courtName,
          sport: live.sport,
          start: live.start,
          end: live.end,
          customerName: live.customerName,
          phone: live.phone,
          totalPrice: live.totalPrice,
          amountPaid: 0,
          status: ReservationStatus.cancelled,
        ),
      );
      await pumpPage(tester, loaded(), createDetailCubit: cubit);

      await tester.tap(find.text('Valentina Dussán'));
      await settle(tester);
      expect(find.text('Jugada'), findsOneWidget);
      expect(find.text('No asistió'), findsWidgets);

      await tester.tap(find.byKey(const Key('cancel-reservation')));
      await settle(tester);
      // Sin motivo no deja cancelar.
      await tester.tap(find.byKey(const Key('confirm-cancel')));
      await tester.pump();
      expect(find.text('Escribe el motivo (mínimo 3 letras).'), findsOneWidget);
      // Motivos rápidos: al tocar uno se escribe en el campo.
      await tester.tap(find.text('El cliente no pagó'));
      await tester.pump();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('cancel-reason')))
            .controller!
            .text,
        'El cliente no pagó',
      );
      await tester.enterText(find.byKey(const Key('cancel-reason')), 'Llueve');
      await tester.tap(find.byKey(const Key('confirm-cancel')));
      await settle(tester);

      verify(() => cancel((id: 'live', reason: 'Llueve'))).called(1);
      expect(find.text('Reserva cancelada.'), findsOneWidget);
      expect(find.byKey(const Key('confirm-cancel')), findsNothing);
      await settle(tester);
      // La agenda se recarga con el cambio.
      verify(() => bloc.add(const ReservationsRefreshed())).called(1);
    });

    testWidgets('no asistió pide confirmación antes de guardar', (
      tester,
    ) async {
      when(() => status(any())).thenAnswer(
        (_) async => designScenario.firstWhere((r) => r.id == 'live'),
      );
      await pumpPage(tester, loaded(), createDetailCubit: cubit);

      await tester.tap(find.text('Valentina Dussán'));
      await settle(tester);
      await tester.tap(find.byKey(const Key('mark-no-show')));
      await settle(tester);
      expect(find.text('¿Marcar como no asistió?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('status-back')));
      await settle(tester);
      verifyNever(() => status(any()));

      await tester.tap(find.byKey(const Key('mark-no-show')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('status-confirm')));
      await settle(tester);
      verify(
        () => status((id: 'live', status: ReservationStatus.noShow)),
      ).called(1);
    });

    testWidgets('antes del turno no se puede marcar jugada ni no asistió', (
      tester,
    ) async {
      final future = Reservation(
        id: 'future',
        courtName: 'Cancha 1',
        sport: Sport.futbol,
        start: DateTime.now().add(const Duration(days: 1)),
        end: DateTime.now().add(const Duration(days: 1, hours: 1)),
        customerName: 'Futuro Cliente',
        phone: '+57 300 000 0000',
        totalPrice: 60000,
        amountPaid: 0,
        status: ReservationStatus.confirmed,
      );
      await pumpPage(
        tester,
        BusinessReservationsState(
          day: day,
          now: now,
          status: ReservationsStatus.success,
          reservations: [future],
        ),
        createDetailCubit: cubit,
      );

      await tester.tap(find.text('Futuro Cliente'));
      await settle(tester);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('mark-no-show')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('mark-completed')))
            .onPressed,
        isNull,
      );
      expect(
        find.byTooltip('Disponible cuando empiece el turno'),
        findsWidgets,
      );
    });

    testWidgets('en solo lectura: sin "Nueva reserva" ni acciones', (
      tester,
    ) async {
      await pumpPage(
        tester,
        loaded(),
        createDetailCubit: cubit,
        canWrite: false,
      );
      expect(find.byTooltip('Nueva reserva'), findsNothing);

      await tester.tap(find.text('Valentina Dussán'));
      await settle(tester);
      expect(find.byKey(const Key('cancel-reservation')), findsNothing);
      expect(find.byKey(const Key('mark-completed')), findsNothing);
      expect(find.text('Cerrar'), findsOneWidget);
    });
  });
}
