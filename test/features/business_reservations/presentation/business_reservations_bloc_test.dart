import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/utils/clock.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation_filter.dart';
import 'package:mi_cancha/features/business_reservations/domain/usecases/get_day_reservations.dart';
import 'package:mi_cancha/features/business_reservations/presentation/bloc/business_reservations_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../reservation_fixtures.dart';

class _MockGetDay extends Mock implements GetDayReservations {}

class _MutableClock extends Clock {
  _MutableClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

void main() {
  late _MockGetDay getDay;
  late _MutableClock clock;

  setUpAll(() => registerFallbackValue(DateTime(2000)));
  setUp(() {
    getDay = _MockGetDay();
    clock = _MutableClock(now);
    when(() => getDay(any())).thenAnswer((_) async => designScenario);
  });

  BusinessReservationsBloc build() => BusinessReservationsBloc(
    getDayReservations: getDay,
    clock: clock,
    tickInterval: null,
  );

  blocTest<BusinessReservationsBloc, BusinessReservationsState>(
    'carga las reservas de hoy',
    build: build,
    act: (bloc) => bloc.add(const ReservationsRequested()),
    expect: () => [
      isA<BusinessReservationsState>()
          .having((s) => s.status, 'status', ReservationsStatus.loading)
          .having((s) => s.day, 'day', day),
      isA<BusinessReservationsState>()
          .having((s) => s.status, 'status', ReservationsStatus.success)
          .having((s) => s.reservations.length, 'reservas', 6),
    ],
    verify: (_) => verify(() => getDay(day)).called(1),
  );

  blocTest<BusinessReservationsBloc, BusinessReservationsState>(
    'emite failure si la carga falla',
    setUp: () => when(() => getDay(any())).thenThrow(Exception('x')),
    build: build,
    act: (bloc) => bloc.add(const ReservationsRequested()),
    skip: 1,
    expect: () => [
      isA<BusinessReservationsState>().having(
        (s) => s.status,
        'status',
        ReservationsStatus.failure,
      ),
    ],
  );

  blocTest<BusinessReservationsBloc, BusinessReservationsState>(
    'el filtro se activa y se desactiva al tocarlo de nuevo',
    build: build,
    act: (bloc) => bloc
      ..add(const ReservationsFilterToggled(ReservationFilter.live))
      ..add(const ReservationsFilterToggled(ReservationFilter.upcoming))
      ..add(const ReservationsFilterToggled(ReservationFilter.upcoming)),
    expect: () => [
      isA<BusinessReservationsState>().having(
        (s) => s.filter,
        'filter',
        ReservationFilter.live,
      ),
      isA<BusinessReservationsState>().having(
        (s) => s.filter,
        'filter',
        ReservationFilter.upcoming,
      ),
      isA<BusinessReservationsState>().having((s) => s.filter, 'filter', null),
    ],
  );

  blocTest<BusinessReservationsBloc, BusinessReservationsState>(
    'el tick del reloj mueve la reserva en juego a pasadas',
    build: build,
    act: (bloc) async {
      bloc.add(const ReservationsRequested());
      await bloc.stream.firstWhere(
        (s) => s.status == ReservationsStatus.success,
      );
      clock.value = DateTime(2026, 10, 9, 20, 45); // terminó la de 7:00–8:30
      bloc.add(const ReservationsClockTicked());
    },
    skip: 2,
    expect: () => [
      isA<BusinessReservationsState>().having(
        (s) => s.agenda.countFor(ReservationFilter.live),
        'en juego',
        1, // ahora la de 7:30–9:00 está en juego
      ),
    ],
  );

  blocTest<BusinessReservationsBloc, BusinessReservationsState>(
    'refrescar conserva el listado si falla',
    build: build,
    act: (bloc) async {
      bloc.add(const ReservationsRequested());
      await bloc.stream.firstWhere(
        (s) => s.status == ReservationsStatus.success,
      );
      when(() => getDay(any())).thenThrow(Exception('offline'));
      bloc.add(const ReservationsRefreshed());
    },
    skip: 2,
    expect: () => [
      isA<BusinessReservationsState>().having(
        (s) => s.isRefreshing,
        'refreshing',
        true,
      ),
      isA<BusinessReservationsState>()
          .having((s) => s.isRefreshing, 'refreshing', false)
          .having((s) => s.status, 'status', ReservationsStatus.success)
          .having((s) => s.reservations.length, 'reservas', 6),
    ],
  );
}
