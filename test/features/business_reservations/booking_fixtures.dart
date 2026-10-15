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

/// 16:00 libre, 17:00 libre, 18:00 libre, 19:00 ocupado, 20:00 libre,
/// 21:00 libre (y 08:00 ya pasó).
final availability = Availability(
  date: '2026-10-15',
  courtId: 'c1',
  slotDuration: 60,
  currency: 'COP',
  maxSlots: 5,
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

Court court(String id, {bool active = true, bool complete = true}) => Court(
  id: id,
  name: 'Cancha $id',
  sport: Sport.futbol,
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
