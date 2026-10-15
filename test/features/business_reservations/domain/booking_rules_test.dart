import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/availability.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/customer.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/new_reservation.dart';
import 'package:mi_cancha/features/business_reservations/domain/usecases/booking_usecases.dart';

import '../booking_fixtures.dart';

void main() {
  group('Availability', () {
    test('ordena los turnos por hora', () {
      expect(availability.slots.first.start.hour, 8);
      expect(availability.slots.last.start.hour, 21);
    });

    test('turnos libres seguidos: corta en el ocupado', () {
      // 16:00 → 16, 17, 18 (19 ocupado).
      expect(availability.consecutiveFrom(1), 3);
      expect(availability.consecutiveFrom(3), 1);
      // Ocupado o pasado: 0.
      expect(availability.consecutiveFrom(4), 0);
      expect(availability.consecutiveFrom(0), 0);
    });

    test('respeta el máximo de turnos', () {
      final long = Availability(
        date: '2026-10-15',
        courtId: 'c1',
        slotDuration: 60,
        currency: 'COP',
        maxSlots: 2,
        slots: [slotAt(16), slotAt(17), slotAt(18)],
      );
      expect(long.consecutiveFrom(0), 2);
    });

    test('un hueco en el horario corta la secuencia', () {
      final gap = Availability(
        date: '2026-10-15',
        courtId: 'c1',
        slotDuration: 60,
        currency: 'COP',
        maxSlots: 5,
        slots: [slotAt(16), slotAt(18)],
      );
      expect(gap.consecutiveFrom(0), 1);
    });

    test('suma el precio de los turnos elegidos', () {
      // 17:00 (60.000) + 18:00 (90.000).
      expect(availability.priceFor(2, 2), 150000);
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
      courtId: 'c1',
      start: '2026-10-15T21:00:00.000Z',
      slots: 2,
      customerId: 'cu1',
    );

    test('reserva mínima válida', () {
      expect(CreateReservation.validate(base, subtotal: 150000), isNull);
    });

    test('descuento mayor que el subtotal', () {
      const r = NewReservation(
        courtId: 'c1',
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
        courtId: 'c1',
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
        courtId: 'c1',
        start: 's',
        slots: 6,
        customerId: 'cu1',
      );
      expect(CreateReservation.validate(r), isNotNull);
    });

    test('cliente nuevo inválido', () {
      const r = NewReservation(
        courtId: 'c1',
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
