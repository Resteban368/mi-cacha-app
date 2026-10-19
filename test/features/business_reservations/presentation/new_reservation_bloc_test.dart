import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/catalogs/domain/usecases/get_catalogs.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/core/utils/clock.dart';
import 'package:mi_cancha/features/business_courts/domain/usecases/get_courts.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/new_reservation.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation_failure.dart';
import 'package:mi_cancha/features/business_reservations/domain/usecases/booking_usecases.dart';
import 'package:mi_cancha/features/business_reservations/presentation/bloc/new_reservation/new_reservation_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../booking_fixtures.dart';

class _MockGetCourts extends Mock implements GetCourts {}

class _MockGetCatalogs extends Mock implements GetCatalogs {}

class _MockGetSportAvailability extends Mock implements GetSportAvailability {}

class _MockSearchCustomers extends Mock implements SearchCustomers {}

class _MockCreate extends Mock implements CreateReservation {}

class _FixedClock extends Clock {
  const _FixedClock();

  @override
  DateTime now() => DateTime(2026, 10, 15, 10);
}

void main() {
  late _MockGetCourts getCourts;
  late _MockGetCatalogs getCatalogs;
  late _MockGetSportAvailability getAvailability;
  late _MockSearchCustomers searchCustomers;
  late _MockCreate create;

  const request = NewReservation(
    target: CourtById('c1'),
    start: '2026-10-15T21:00:00.000Z',
    slots: 2,
    customerId: 'cu1',
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue((sport: Sport.futbol, day: DateTime(2026)));
    registerFallbackValue(request);
  });

  setUp(() {
    getCourts = _MockGetCourts();
    getCatalogs = _MockGetCatalogs();
    getAvailability = _MockGetSportAvailability();
    searchCustomers = _MockSearchCustomers();
    create = _MockCreate();
    when(() => getCourts(any())).thenAnswer(
      (_) async => [
        court('c0', complete: false),
        court('c1'),
        court('c2'),
        court('p1', sport: Sport.padel),
        court('b1', sport: Sport.baloncesto, active: false),
      ],
    );
    when(() => getCatalogs(any())).thenAnswer((_) async => catalogs);
    when(() => getAvailability(any())).thenAnswer((_) async => availability);
    when(() => searchCustomers(any())).thenAnswer((_) async => [laura]);
  });

  NewReservationBloc build({Duration debounce = Duration.zero}) =>
      NewReservationBloc(
        getCourts: getCourts,
        getCatalogs: getCatalogs,
        getSportAvailability: getAvailability,
        searchCustomers: searchCustomers,
        createReservation: create,
        clock: const _FixedClock(),
        searchDebounce: debounce,
      );

  final ready = NewReservationState(
    day: DateTime(2026, 10, 15),
    load: NewReservationLoad.ready,
    courts: [court('c0', complete: false), court('c1'), court('c2')],
    paymentMethods: const [efectivo, nequi],
    sport: Sport.futbol,
    availabilityLoad: AvailabilityLoad.ready,
    availability: availability,
  );

  group('al empezar', () {
    blocTest<NewReservationBloc, NewReservationState>(
      'elige el primer deporte con canchas, carga sus turnos y los clientes',
      build: build,
      act: (bloc) => bloc.add(const NewReservationStarted()),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        final s = bloc.state;
        expect(s.load, NewReservationLoad.ready);
        expect(s.sport, Sport.futbol);
        // Solo deportes con canchas reservables (baloncesto está inactiva).
        expect(s.sports, [Sport.futbol, Sport.padel]);
        // c0 está incompleta: no aparece y se avisa.
        expect(s.hiddenCourtCount, 1);
        expect(s.paymentMethods.map((m) => m.code), ['EFECTIVO', 'NEQUI']);
        expect(s.availability, availability);
        expect(s.customerResults, [laura]);
        verify(
          () => getAvailability((
            sport: Sport.futbol,
            day: DateTime(2026, 10, 15),
          )),
        ).called(1);
        verify(() => searchCustomers('')).called(1);
      },
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'desde la agenda: el deporte de esa cancha y su tarjeta resaltada; '
      'un día pasado vuelve a hoy',
      build: build,
      act: (bloc) => bloc.add(
        NewReservationStarted(courtId: 'p1', day: DateTime(2026, 10, 1)),
      ),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.sport, Sport.padel);
        expect(bloc.state.focusCourtId, 'p1');
        expect(bloc.state.day, DateTime(2026, 10, 15));
      },
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'error al cargar las canchas',
      setUp: () => when(() => getCourts(any())).thenThrow(Exception()),
      build: build,
      act: (bloc) => bloc.add(const NewReservationStarted()),
      verify: (bloc) => expect(bloc.state.load, NewReservationLoad.failure),
    );
  });

  group('deporte y día', () {
    blocTest<NewReservationBloc, NewReservationState>(
      'cambiar de deporte recarga los turnos y limpia la selección',
      build: build,
      seed: () => ready.copyWith(
        selectedCourtId: () => 'c1',
        selectedStart: () => at(16),
        slotCount: 2,
      ),
      act: (bloc) => bloc.add(const NewReservationSportSelected(Sport.padel)),
      verify: (bloc) {
        expect(bloc.state.sport, Sport.padel);
        expect(bloc.state.selectedStart, isNull);
        expect(bloc.state.selectedCourtId, isNull);
        expect(bloc.state.slotCount, 1);
        verify(
          () => getAvailability((
            sport: Sport.padel,
            day: DateTime(2026, 10, 15),
          )),
        ).called(1);
      },
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'cambiar de día recarga los turnos y borra la selección',
      build: build,
      seed: () => ready.copyWith(
        selectedCourtId: () => 'c1',
        selectedStart: () => at(16),
      ),
      act: (bloc) =>
          bloc.add(NewReservationDaySelected(DateTime(2026, 10, 16))),
      verify: (bloc) {
        expect(bloc.state.day, DateTime(2026, 10, 16));
        expect(bloc.state.selectedStart, isNull);
        verify(
          () => getAvailability((
            sport: Sport.futbol,
            day: DateTime(2026, 10, 16),
          )),
        ).called(1);
      },
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'no permite días pasados',
      build: build,
      seed: () => ready,
      act: (bloc) =>
          bloc.add(NewReservationDaySelected(DateTime(2026, 10, 14))),
      expect: () => const <NewReservationState>[],
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'gana el último deporte elegido',
      setUp: () {
        when(
          () => getAvailability((
            sport: Sport.padel,
            day: DateTime(2026, 10, 15),
          )),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return availability;
        });
      },
      build: build,
      seed: () => ready.copyWith(sport: () => Sport.baloncesto),
      act: (bloc) => bloc
        ..add(const NewReservationSportSelected(Sport.padel))
        ..add(const NewReservationSportSelected(Sport.futbol)),
      wait: const Duration(milliseconds: 60),
      verify: (bloc) {
        expect(bloc.state.sport, Sport.futbol);
        expect(bloc.state.availabilityLoad, AvailabilityLoad.ready);
      },
    );
  });

  group('turnos por cancha', () {
    blocTest<NewReservationBloc, NewReservationState>(
      'elige el inicio, extiende tocando un turno libre seguido y deselecciona',
      build: build,
      seed: () => ready,
      act: (bloc) => bloc
        ..add(NewReservationSlotTapped(courtId: 'c1', start: at(16)))
        ..add(NewReservationSlotTapped(courtId: 'c1', start: at(18)))
        ..add(NewReservationSlotTapped(courtId: 'c1', start: at(16))),
      expect: () => [
        ready.copyWith(
          selectedCourtId: () => 'c1',
          selectedStart: () => at(16),
        ),
        ready.copyWith(
          selectedCourtId: () => 'c1',
          selectedStart: () => at(16),
          slotCount: 3,
        ),
        ready.copyWith(
          selectedCourtId: () => null,
          selectedStart: () => null,
          slotCount: 1,
        ),
      ],
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'tocar un turno de otra cancha la elige (no extiende)',
      build: build,
      seed: () => ready.copyWith(
        selectedCourtId: () => 'c1',
        selectedStart: () => at(17),
      ),
      act: (bloc) =>
          bloc.add(NewReservationSlotTapped(courtId: 'c2', start: at(18))),
      verify: (bloc) {
        expect(bloc.state.selectedCourtId, 'c2');
        expect(bloc.state.selectedStart, at(18));
        expect(bloc.state.slotCount, 1);
        expect(bloc.state.subtotal, 50000);
      },
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'no elige turnos ocupados ni pasados',
      build: build,
      seed: () => ready,
      act: (bloc) => bloc
        ..add(NewReservationSlotTapped(courtId: 'c1', start: at(19)))
        ..add(NewReservationSlotTapped(courtId: 'c1', start: at(8)))
        ..add(NewReservationSlotTapped(courtId: 'c2', start: at(16))),
      expect: () => const <NewReservationState>[],
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'la duración no supera los turnos libres seguidos',
      build: build,
      seed: () => ready.copyWith(
        selectedCourtId: () => 'c1',
        selectedStart: () => at(16),
      ),
      act: (bloc) => bloc.add(const NewReservationSlotCountChanged(5)),
      verify: (bloc) {
        expect(bloc.state.slotCount, 3);
        expect(bloc.state.subtotal, 60000 + 60000 + 90000);
        expect(bloc.state.selectedCourt!.court.id, 'c1');
        expect(bloc.state.priceMayVary, isFalse);
      },
    );
  });

  group('cualquier cancha', () {
    final any = ready.copyWith(anyCourt: true);

    blocTest<NewReservationBloc, NewReservationState>(
      'elige la hora; asigna la primera cancha libre y estima su valor',
      build: build,
      seed: () => any,
      act: (bloc) => bloc
        ..add(NewReservationSlotTapped(start: at(17)))
        ..add(const NewReservationSlotCountChanged(3)),
      verify: (bloc) {
        final s = bloc.state;
        expect(s.selectedStart, at(17));
        expect(s.slotCount, 3);
        // c1 tiene 2 seguidos desde las 17:00; c2 tiene 3.
        expect(s.maxSlotCount, 3);
        expect(s.selectedCourt!.court.id, 'c2');
        expect(s.subtotal, 150000);
        expect(s.lowestSubtotal, 150000);
      },
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'si las canchas cobran distinto, valida con el valor más bajo',
      build: build,
      seed: () => any.copyWith(selectedStart: () => at(17), slotCount: 2),
      verify: (bloc) {
        // Asignaría c1 (60.000 + 90.000), pero c2 vale 100.000.
        expect(bloc.state.selectedCourt!.court.id, 'c1');
        expect(bloc.state.subtotal, 150000);
        expect(bloc.state.lowestSubtotal, 100000);
        expect(bloc.state.priceMayVary, isTrue);
      },
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'extiende tocando un horario siguiente dentro del alcance',
      build: build,
      seed: () => any.copyWith(selectedStart: () => at(17)),
      act: (bloc) => bloc
        ..add(NewReservationSlotTapped(start: at(19)))
        ..add(NewReservationSlotTapped(start: at(17))),
      expect: () => [
        any.copyWith(selectedStart: () => at(17), slotCount: 3),
        any.copyWith(selectedStart: () => null, slotCount: 1),
      ],
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'al activarlo conserva la hora; al apagarlo queda la cancha asignada',
      build: build,
      seed: () => ready.copyWith(
        selectedCourtId: () => 'c2',
        selectedStart: () => at(17),
        slotCount: 3,
      ),
      act: (bloc) => bloc
        ..add(const NewReservationAnyCourtToggled(true))
        ..add(const NewReservationSlotCountChanged(2))
        ..add(const NewReservationAnyCourtToggled(false)),
      verify: (bloc) {
        final s = bloc.state;
        expect(s.anyCourt, isFalse);
        expect(s.selectedStart, at(17));
        expect(s.slotCount, 2);
        // Con 2 turnos desde las 17:00 la API asignaría c1.
        expect(s.selectedCourtId, 'c1');
      },
    );
  });

  blocTest<NewReservationBloc, NewReservationState>(
    'búsqueda de clientes: gana la última',
    build: () => build(debounce: const Duration(milliseconds: 20)),
    seed: () => ready,
    act: (bloc) => bloc
      ..add(const NewReservationCustomerQueryChanged('la'))
      ..add(const NewReservationCustomerQueryChanged('laura')),
    wait: const Duration(milliseconds: 60),
    verify: (_) {
      verifyNever(() => searchCustomers('la'));
      verify(() => searchCustomers('laura')).called(1);
    },
  );

  group('confirmar', () {
    final chosen = ready.copyWith(
      selectedCourtId: () => 'c1',
      selectedStart: () => at(20),
      slotCount: 2,
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'crea la reserva',
      setUp: () => when(() => create(any())).thenAnswer((_) async => created),
      build: build,
      seed: () => chosen,
      act: (bloc) => bloc.add(const NewReservationSubmitted(request)),
      expect: () => [
        chosen.copyWith(submit: NewReservationSubmit.submitting),
        chosen.copyWith(
          submit: NewReservationSubmit.success,
          created: () => created,
        ),
      ],
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'turno ocupado: avisa y recarga la disponibilidad',
      setUp: () => when(() => create(any())).thenThrow(
        const ReservationException(
          ReservationFailure.slotTaken,
          message: 'No hay canchas de fútbol libres en ese horario',
        ),
      ),
      build: build,
      seed: () => chosen,
      act: (bloc) => bloc.add(const NewReservationSubmitted(request)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.failure, ReservationFailure.slotTaken);
        expect(bloc.state.selectedStart, isNull);
        verify(() => getAvailability(any())).called(1);
      },
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'descuento mayor que el subtotal no llega a la API',
      build: build,
      seed: () => chosen,
      act: (bloc) => bloc.add(
        const NewReservationSubmitted(
          NewReservation(
            target: CourtById('c1'),
            start: 's',
            slots: 2,
            customerId: 'cu1',
            discount: 999999,
          ),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.failure, ReservationFailure.invalid);
        verifyNever(() => create(any()));
      },
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'cualquier cancha: el pago no supera el valor más bajo posible',
      build: build,
      seed: () => ready.copyWith(
        anyCourt: true,
        selectedStart: () => at(17),
        slotCount: 2,
      ),
      act: (bloc) => bloc.add(
        const NewReservationSubmitted(
          NewReservation(
            target: AnyCourtOfSport(Sport.futbol),
            start: 's',
            slots: 2,
            customerId: 'cu1',
            payment: NewPayment(amount: 150000, method: 'EFECTIVO'),
          ),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.failure, ReservationFailure.invalid);
        verifyNever(() => create(any()));
      },
    );
  });

  group('varias canchas a la vez', () {
    final selected = ready.copyWith(
      selectedCourtId: () => 'c1',
      selectedStart: () => at(17),
    );

    test('ofrece las canchas libres en la misma franja y suma sus precios', () {
      expect(selected.addableCourts.map((c) => c.court.id), ['c2']);
      final both = selected.copyWith(extraCourtIds: ['c2']);
      expect(both.selectedCourts.map((c) => c.court.id), ['c1', 'c2']);
      // c1 17:00 = 60.000 y c2 17:00 = 50.000.
      expect(both.subtotal, 110000);
      // c1 tiene 17 y 18 libres; c2, 17 a 19: la duración común es 2.
      expect(both.maxSlotCount, 2);
      expect(both.addableCourts, isEmpty);
    });

    blocTest<NewReservationBloc, NewReservationState>(
      'suma y quita una cancha; tocar otro turno deja una sola',
      build: build,
      seed: () => selected,
      act: (bloc) => bloc
        ..add(const NewReservationExtraCourtToggled('c2'))
        ..add(const NewReservationExtraCourtToggled('c2'))
        ..add(const NewReservationExtraCourtToggled('c2'))
        ..add(NewReservationSlotTapped(courtId: 'c1', start: at(20))),
      expect: () => [
        selected.copyWith(extraCourtIds: ['c2']),
        selected,
        selected.copyWith(extraCourtIds: ['c2']),
        selected.copyWith(selectedStart: () => at(20)),
      ],
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'no suma una cancha que no está libre en la franja',
      build: build,
      seed: () => ready.copyWith(
        selectedCourtId: () => 'c1',
        selectedStart: () => at(16),
      ),
      act: (bloc) => bloc.add(const NewReservationExtraCourtToggled('c2')),
      expect: () => const <NewReservationState>[],
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'con cualquier cancha elige cuántas, hasta las libres a esa hora',
      build: build,
      seed: () => ready.copyWith(anyCourt: true, selectedStart: () => at(17)),
      act: (bloc) => bloc
        ..add(const NewReservationAnyCourtCountChanged(3))
        ..add(const NewReservationAnyCourtCountChanged(1)),
      verify: (bloc) {
        expect(bloc.state.anyCourtCount, 1);
      },
      expect: () => [
        // A las 17:00 hay 2 canchas libres: 3 se ajusta a 2.
        ready.copyWith(
          anyCourt: true,
          selectedStart: () => at(17),
          anyCourtCount: 2,
        ),
        ready.copyWith(anyCourt: true, selectedStart: () => at(17)),
      ],
    );
  });
}
