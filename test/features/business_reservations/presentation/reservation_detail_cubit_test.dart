import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation_failure.dart';
import 'package:mi_cancha/features/business_reservations/domain/usecases/booking_usecases.dart';
import 'package:mi_cancha/features/business_reservations/presentation/bloc/reservation_detail/reservation_detail_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../booking_fixtures.dart';

class _MockGet extends Mock implements GetReservation {}

class _MockCancel extends Mock implements CancelReservation {}

class _MockStatus extends Mock implements UpdateReservationStatus {}

void main() {
  late _MockGet get;
  late _MockCancel cancel;
  late _MockStatus status;

  setUpAll(() {
    registerFallbackValue((id: 'r1', reason: 'x'));
    registerFallbackValue((id: 'r1', status: ReservationStatus.completed));
  });

  setUp(() {
    get = _MockGet();
    cancel = _MockCancel();
    status = _MockStatus();
    when(() => get(any())).thenAnswer((_) async => created);
  });

  ReservationDetailCubit build() => ReservationDetailCubit(
    getReservation: get,
    cancelReservation: cancel,
    updateStatus: status,
  );

  blocTest<ReservationDetailCubit, ReservationDetailState>(
    'muestra la reserva y trae el detalle',
    build: build,
    act: (cubit) => cubit.load(created),
    verify: (cubit) {
      expect(cubit.state.reservation, created);
      verify(() => get('r1')).called(1);
    },
  );

  blocTest<ReservationDetailCubit, ReservationDetailState>(
    'cancelar con motivo marca el cambio',
    setUp: () => when(() => cancel(any())).thenAnswer(
      (_) async => Reservation(
        id: 'r1',
        courtName: created.courtName,
        sport: created.sport,
        start: created.start,
        end: created.end,
        customerName: created.customerName,
        phone: created.phone,
        totalPrice: created.totalPrice,
        amountPaid: 0,
        status: ReservationStatus.cancelled,
        cancellationReason: 'Llueve',
      ),
    ),
    build: build,
    seed: () => ReservationDetailState(
      load: ReservationDetailLoad.ready,
      reservation: created,
    ),
    act: (cubit) => cubit.cancel('Llueve'),
    verify: (cubit) {
      expect(cubit.state.action, ReservationAction.done);
      expect(cubit.state.changed, isTrue);
      expect(cubit.state.reservation!.status, ReservationStatus.cancelled);
      verify(() => cancel((id: 'r1', reason: 'Llueve'))).called(1);
    },
  );

  blocTest<ReservationDetailCubit, ReservationDetailState>(
    'marcar jugada',
    setUp: () => when(() => status(any())).thenAnswer((_) async => created),
    build: build,
    seed: () => ReservationDetailState(
      load: ReservationDetailLoad.ready,
      reservation: created,
    ),
    act: (cubit) => cubit.setStatus(ReservationStatus.completed),
    verify: (_) => verify(
      () => status((id: 'r1', status: ReservationStatus.completed)),
    ).called(1),
  );

  blocTest<ReservationDetailCubit, ReservationDetailState>(
    'error con el mensaje del backend',
    setUp: () => when(() => cancel(any())).thenThrow(
      const ReservationException(
        ReservationFailure.notCancellable,
        message: 'Solo se pueden cancelar reservas confirmadas',
      ),
    ),
    build: build,
    seed: () => ReservationDetailState(
      load: ReservationDetailLoad.ready,
      reservation: created,
    ),
    act: (cubit) => cubit.cancel('Llueve'),
    verify: (cubit) {
      expect(cubit.state.action, ReservationAction.failure);
      expect(
        cubit.state.failureMessage,
        'Solo se pueden cancelar reservas confirmadas',
      );
      expect(cubit.state.changed, isFalse);
    },
  );
}
