import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/catalogs/domain/usecases/get_catalogs.dart';
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

class _MockGetAvailability extends Mock implements GetAvailability {}

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
  late _MockGetAvailability getAvailability;
  late _MockSearchCustomers searchCustomers;
  late _MockCreate create;

  const request = NewReservation(
    courtId: 'c1',
    start: '2026-10-15T21:00:00.000Z',
    slots: 2,
    customerId: 'cu1',
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue((courtId: 'c1', day: DateTime(2026)));
    registerFallbackValue(request);
  });

  setUp(() {
    getCourts = _MockGetCourts();
    getCatalogs = _MockGetCatalogs();
    getAvailability = _MockGetAvailability();
    searchCustomers = _MockSearchCustomers();
    create = _MockCreate();
    when(() => getCourts(any())).thenAnswer(
      (_) async => [court('c0', complete: false), court('c1'), court('c2')],
    );
    when(() => getCatalogs(any())).thenAnswer((_) async => catalogs);
    when(() => getAvailability(any())).thenAnswer((_) async => availability);
    when(() => searchCustomers(any())).thenAnswer((_) async => [laura]);
  });

  NewReservationBloc build() => NewReservationBloc(
    getCourts: getCourts,
    getCatalogs: getCatalogs,
    getAvailability: getAvailability,
    searchCustomers: searchCustomers,
    createReservation: create,
    clock: const _FixedClock(),
    searchDebounce: Duration.zero,
  );

  final ready = NewReservationState(
    day: DateTime(2026, 10, 15),
    load: NewReservationLoad.ready,
    courts: [court('c1'), court('c2')],
    paymentMethods: const [efectivo, nequi],
    court: court('c1'),
    availabilityLoad: AvailabilityLoad.ready,
    availability: availability,
  );

  group('al empezar', () {
    blocTest<NewReservationBloc, NewReservationState>(
      'elige la primera cancha reservable, carga turnos y clientes recientes',
      build: build,
      act: (bloc) => bloc.add(const NewReservationStarted()),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        final s = bloc.state;
        expect(s.load, NewReservationLoad.ready);
        expect(s.court!.id, 'c1');
        // Reservables primero; la incompleta al final (deshabilitada).
        expect(s.courts.map((c) => c.id), ['c1', 'c2', 'c0']);
        // Métodos de pago en el orden del catálogo.
        expect(s.paymentMethods.map((m) => m.code), ['EFECTIVO', 'NEQUI']);
        expect(s.availability, availability);
        expect(s.customerResults, [laura]);
        verify(
          () => getAvailability((courtId: 'c1', day: DateTime(2026, 10, 15))),
        ).called(1);
        verify(() => searchCustomers('')).called(1);
      },
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'respeta la cancha y el día pedidos; un día pasado vuelve a hoy',
      build: build,
      act: (bloc) => bloc.add(
        NewReservationStarted(courtId: 'c2', day: DateTime(2026, 10, 1)),
      ),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.court!.id, 'c2');
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

  group('turnos', () {
    blocTest<NewReservationBloc, NewReservationState>(
      'elige el inicio, extiende tocando un turno libre seguido y deselecciona',
      build: build,
      seed: () => ready,
      act: (bloc) => bloc
        ..add(const NewReservationSlotTapped(1)) // 16:00
        ..add(const NewReservationSlotTapped(3)) // hasta 18:00
        ..add(const NewReservationSlotTapped(1)), // quitar
      expect: () => [
        ready.copyWith(startIndex: () => 1),
        ready.copyWith(startIndex: () => 1, slotCount: 3),
        ready.copyWith(startIndex: () => null, slotCount: 1),
      ],
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'no elige turnos ocupados ni pasados',
      build: build,
      seed: () => ready,
      act: (bloc) => bloc
        ..add(const NewReservationSlotTapped(4)) // ocupado
        ..add(const NewReservationSlotTapped(0)), // pasado
      expect: () => const <NewReservationState>[],
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'la duración no supera los turnos libres seguidos',
      build: build,
      seed: () => ready.copyWith(startIndex: () => 1),
      act: (bloc) => bloc.add(const NewReservationSlotCountChanged(5)),
      verify: (bloc) {
        expect(bloc.state.slotCount, 3);
        expect(bloc.state.subtotal, 60000 + 60000 + 90000);
      },
    );

    blocTest<NewReservationBloc, NewReservationState>(
      'cambiar de día recarga los turnos y borra la selección',
      build: build,
      seed: () => ready.copyWith(startIndex: () => 1),
      act: (bloc) =>
          bloc.add(NewReservationDaySelected(DateTime(2026, 10, 16))),
      verify: (bloc) {
        expect(bloc.state.day, DateTime(2026, 10, 16));
        expect(bloc.state.startIndex, isNull);
        verify(
          () => getAvailability((courtId: 'c1', day: DateTime(2026, 10, 16))),
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
  });

  blocTest<NewReservationBloc, NewReservationState>(
    'búsqueda de clientes: gana la última',
    build: () => NewReservationBloc(
      getCourts: getCourts,
      getCatalogs: getCatalogs,
      getAvailability: getAvailability,
      searchCustomers: searchCustomers,
      createReservation: create,
      clock: const _FixedClock(),
      searchDebounce: const Duration(milliseconds: 20),
    ),
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
    final chosen = ready.copyWith(startIndex: () => 5, slotCount: 2);

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
          message: 'La cancha ya está reservada en ese horario',
        ),
      ),
      build: build,
      seed: () => chosen,
      act: (bloc) => bloc.add(const NewReservationSubmitted(request)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.failure, ReservationFailure.slotTaken);
        expect(bloc.state.startIndex, isNull);
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
            courtId: 'c1',
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
  });
}
