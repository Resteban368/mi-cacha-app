import 'package:mi_cancha/core/catalogs/domain/entities/app_catalogs.dart';
import 'package:mi_cancha/core/catalogs/domain/entities/catalog_payment_method.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/availability.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/customer.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';

/// Turno de una hora el 15 de octubre de 2026 a la [hour] local.
Slot slotAt(int hour, {SlotStatus status = SlotStatus.available, int? price}) {
  final start = DateTime(2026, 10, 15, hour);
  return Slot(
    startIso: start.toUtc().toIso8601String(),
    start: start,
    end: start.add(const Duration(hours: 1)),
    status: status,
    price: price ?? (hour >= 18 ? 90000 : 60000),
  );
}

/// Cancha c1: 16:00, 17:00 y 18:00 libres, 19:00 ocupado, 20:00 y 21:00
/// libres (y 08:00 ya pasó). Precios de 60.000 y 90.000 desde las 18:00.
final c1Slots = CourtSlots(
  court: availabilityCourt('c1'),
  availableCount: 5,
  slots: [
    slotAt(8, status: SlotStatus.past),
    slotAt(16),
    slotAt(17),
    slotAt(18),
    slotAt(19, status: SlotStatus.booked),
    slotAt(20),
    slotAt(21),
  ],
);

/// Cancha c2 (más barata, 50.000): 16:00 ocupado, 17:00 a 19:00 libres,
/// 20:00 ocupado y 21:00 libre.
final c2Slots = CourtSlots(
  court: availabilityCourt('c2', covered: true),
  availableCount: 4,
  slots: [
    slotAt(16, status: SlotStatus.booked, price: 50000),
    slotAt(17, price: 50000),
    slotAt(18, price: 50000),
    slotAt(19, price: 50000),
    slotAt(20, status: SlotStatus.booked, price: 50000),
    slotAt(21, price: 50000),
  ],
);

AvailabilityCourt availabilityCourt(String id, {bool covered = false}) =>
    AvailabilityCourt(
      id: id,
      name: 'Cancha $id',
      sport: Sport.futbol,
      isCovered: covered,
      slotDuration: 60,
      photoUrl: 'https://example.com/$id.jpg',
    );

/// Fútbol el 15 de octubre: canchas c1 y c2 (en ese orden, como la API).
final availability = SportAvailability(
  date: '2026-10-15',
  sport: Sport.futbol,
  maxSlots: 5,
  courts: [c1Slots, c2Slots],
);

DateTime at(int hour) => DateTime(2026, 10, 15, hour);

Court court(
  String id, {
  bool active = true,
  bool complete = true,
  Sport sport = Sport.futbol,
}) => Court(
  id: id,
  name: 'Cancha $id',
  sport: sport,
  isActive: active,
  isComplete: complete,
  isBookable: active && complete,
);

const nequi = CatalogPaymentMethod(
  id: 'p2',
  code: 'NEQUI',
  name: 'Nequi',
  active: true,
  sortOrder: 2,
  requiresReference: true,
);

const efectivo = CatalogPaymentMethod(
  id: 'p1',
  code: 'EFECTIVO',
  name: 'Efectivo',
  active: true,
  sortOrder: 1,
  requiresReference: false,
);

const catalogs = AppCatalogs(amenities: [], paymentMethods: [nequi, efectivo]);

const laura = Customer(
  id: 'cu1',
  name: 'Laura Gómez',
  phone: '3115550001',
  documentId: '1075111222',
);

final created = Reservation(
  id: 'r1',
  courtId: 'c1',
  courtName: 'Cancha c1',
  sport: Sport.futbol,
  start: DateTime(2026, 10, 15, 16),
  end: DateTime(2026, 10, 15, 18),
  customerName: 'Laura Gómez',
  phone: '3115550001',
  subtotal: 120000,
  discount: 20000,
  totalPrice: 100000,
  amountPaid: 50000,
  status: ReservationStatus.confirmed,
);
