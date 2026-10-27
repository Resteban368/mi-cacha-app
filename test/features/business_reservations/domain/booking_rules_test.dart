import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/availability.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/customer.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/new_reservation.dart';
import 'package:mi_cancha/features/business_reservations/domain/usecases/booking_usecases.dart';

import '../booking_fixtures.dart';

void main() {
  group('CourtSlots', () {
    test('ordena los turnos por hora', () {
      expect(c1Slots.slots.first.start.hour, 8);
      expect(c1Slots.slots.last.start.hour, 21);
    });

    test('turnos libres seguidos: corta en el ocupado', () {
      // 16:00 → 16, 17, 18 (19 ocupado).
      expect(c1Slots.consecutiveFrom(1, 5), 3);
      expect(c1Slots.consecutiveFrom(3, 5), 1);
      // Ocupado o pasado: 0.
      expect(c1Slots.consecutiveFrom(4, 5), 0);
      expect(c1Slots.consecutiveFrom(0, 5), 0);
      expect(c1Slots.consecutiveFrom(-1, 5), 0);
    });

    test('respeta el máximo de turnos', () {
      expect(c1Slots.consecutiveFrom(1, 2), 2);
    });

    test('un hueco en el horario corta la secuencia', () {
      final gap = CourtSlots(
        court: availabilityCourt('c1'),
        availableCount: 2,
        slots: [slotAt(16), slotAt(18)],
      );
      expect(gap.consecutiveFrom(0, 5), 1);
    });

    test('suma el precio de los turnos elegidos', () {
      // 17:00 (60.000) + 18:00 (90.000).
      expect(c1Slots.priceFor(2, 2), 150000);
      expect(c1Slots.indexOf(at(17)), 2);
      expect(c1Slots.indexOf(at(23)), -1);
    });
  });

  group('SportAvailability (cualquier cancha)', () {
    test('une los horarios de todas las canchas', () {
      final slots = availability.anyCourtSlots;
      expect(slots.map((s) => s.start.hour), [8, 16, 17, 18, 19, 20, 21]);
      // 16:00 solo libre en c1; 19:00 solo en c2; 08:00 pasado.
      expect(slots[0].status, SlotStatus.past);
      expect(slots[1].freeCourts, 1);
      expect(slots[1].price, 60000);
      // 17:00 libre en las dos: el precio más bajo y "desde".
      expect(slots[2].freeCourts, 2);
      expect(slots[2].price, 50000);
      expect(slots[2].priceVaries, isTrue);
      expect(slots[4].status, SlotStatus.available);
      expect(slots[4].priceVaries, isFalse);
    });

    test('ocupado si ninguna cancha lo tiene libre', () {
      final full = SportAvailability(
        date: '2026-10-15',
        sport: Sport.futbol,
        maxSlots: 5,
        courts: [
          CourtSlots(
            court: availabilityCourt('c1'),
            availableCount: 0,
            slots: [slotAt(16, status: SlotStatus.booked)],
          ),
          CourtSlots(
            court: availabilityCourt('c2'),
            availableCount: 0,
            slots: [slotAt(16, status: SlotStatus.past)],
          ),
        ],
      );
      expect(full.anyCourtSlots.single.status, SlotStatus.booked);
      expect(full.anyCourtReach(at(16)), 0);
    });

    test('alcance: la cancha con más turnos libres seguidos', () {
      expect(availability.anyCourtReach(at(16)), 3); // c1
      expect(availability.anyCourtReach(at(17)), 3); // c2: 17, 18, 19
      expect(availability.anyCourtReach(at(8)), 0);
    });

    test('asigna como la API: la primera por nombre con turnos libres', () {
      expect(availability.firstFreeCourt(at(17), 2)!.court.id, 'c1');
      expect(availability.firstFreeCourt(at(17), 3)!.court.id, 'c2');
      expect(availability.firstFreeCourt(at(19), 1)!.court.id, 'c2');
      expect(availability.firstFreeCourt(at(16), 4), isNull);
    });

    test('valor más bajo posible', () {
      // c1: 60.000 + 90.000; c2: 50.000 + 50.000.
      expect(availability.lowestPriceAt(at(17), 2), 100000);
      expect(availability.lowestPriceAt(at(16), 1), 60000);
      expect(availability.lowestPriceAt(at(16), 5), isNull);
    });
  });

  group('turnos vencidos (15 min de gracia)', () {
    // Turno de 6:00 a 7:00 p. m.
    final slot = slotAt(18);
    DateTime clock(int hour, int minute) =>
        DateTime(2026, 10, 15, hour, minute);

    test('la gracia es de 15 minutos', () {
      expect(kLateBookingGrace, const Duration(minutes: 15));
    });

    test('5:50 p. m.: se puede reservar', () {
      expect(slot.isExpiredAt(clock(17, 50)), isFalse);
    });

    test('6:05 p. m.: se puede reservar', () {
      expect(slot.isExpiredAt(clock(18, 5)), isFalse);
    });

    test('6:15 p. m.: último momento para reservar', () {
      expect(slot.isExpiredAt(clock(18, 15)), isFalse);
    });

    test('6:16 p. m.: vencido, se oculta como los pasados', () {
      expect(slot.isExpiredAt(clock(18, 16)), isTrue);
    });

    test('un turno que ya terminó siempre está vencido', () {
      expect(
        slotAt(8, status: SlotStatus.past).isExpiredAt(clock(7, 0)),
        isTrue,
      );
    });

    test('cualquier cancha aplica la misma regla', () {
      final any = availability.anyCourtSlots.firstWhere(
        (s) => s.start.hour == 18,
      );
      expect(any.isExpiredAt(clock(17, 50)), isFalse);
      expect(any.isExpiredAt(clock(18, 5)), isFalse);
      expect(any.isExpiredAt(clock(18, 15)), isFalse);
      expect(any.isExpiredAt(clock(18, 16)), isTrue);
    });
  });

  group('NewCustomer', () {
    test('valida como la API', () {
      expect(NewCustomer.validateName('L'), isNotNull);
      expect(NewCustomer.validateName('Laura'), isNull);
      expect(NewCustomer.validatePhone('311 555 0001'), isNull);
      expect(NewCustomer.validatePhone('+57 (311) 555-0001'), isNull);
      expect(NewCustomer.validatePhone('31155'), isNotNull);
      expect(NewCustomer.validatePhone('311abc5555'), isNotNull);
      expect(NewCustomer.validateDocument('1.075.111.222'), isNull);
      expect(NewCustomer.validateDocument('12'), isNotNull);
    });
  });

  group('CreateReservation.validate', () {
    const base = NewReservation(
      target: CourtById('c1'),
      start: '2026-10-15T21:00:00.000Z',
      slots: 2,
      customerId: 'cu1',
    );

    test('reserva mínima válida', () {
      expect(CreateReservation.validate(base, subtotal: 150000), isNull);
    });

    test('descuento mayor que el subtotal', () {
      const r = NewReservation(
        target: CourtById('c1'),
        start: 's',
        slots: 1,
        customerId: 'cu1',
        discount: 200000,
      );
      expect(
        CreateReservation.validate(r, subtotal: 150000),
        'El descuento no puede superar el valor de la reserva.',
      );
    });

    test('pago mayor que el total', () {
      const r = NewReservation(
        target: CourtById('c1'),
        start: 's',
        slots: 1,
        customerId: 'cu1',
        discount: 50000,
        payment: NewPayment(amount: 120000, method: 'EFECTIVO'),
      );
      expect(
        CreateReservation.validate(r, subtotal: 150000),
        'El pago no puede superar el total de la reserva.',
      );
    });

    test('más turnos de los permitidos', () {
      const r = NewReservation(
        target: CourtById('c1'),
        start: 's',
        slots: 6,
        customerId: 'cu1',
      );
      expect(CreateReservation.validate(r), isNotNull);
    });

    test('cliente nuevo inválido', () {
      const r = NewReservation(
        target: CourtById('c1'),
        start: 's',
        slots: 1,
        customer: NewCustomer(name: 'Laura', phone: '12', documentId: '1234'),
      );
      expect(CreateReservation.validate(r), contains('Teléfono'));
    });
  });

  test('motivo de cancelación de 3 a 200 caracteres', () {
    expect(CancelReservation.validateReason('no'), isNotNull);
    expect(CancelReservation.validateReason('Llueve'), isNull);
    expect(CancelReservation.validateReason('x' * 201), isNotNull);
  });

  test('SlotStatus desconocido cuenta como pasado (no se elige)', () {
    expect(SlotStatus.fromApi('RARO'), SlotStatus.past);
  });
}
