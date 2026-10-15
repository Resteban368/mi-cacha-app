import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';

final day = DateTime(2026, 10, 9);
final now = DateTime(2026, 10, 9, 19, 15);

Reservation reservation({
  required String id,
  required int startHour,
  int startMinute = 0,
  int minutes = 60,
  int total = 100000,
  int paid = 100000,
  ReservationStatus status = ReservationStatus.confirmed,
  String? name,
}) {
  final start = DateTime(2026, 10, 9, startHour, startMinute);
  return Reservation(
    id: id,
    courtName: 'Cancha $id',
    sport: Sport.futbol,
    start: start,
    end: start.add(Duration(minutes: minutes)),
    customerName: name ?? 'Cliente $id',
    phone: '+57 300 000 0000',
    totalPrice: total,
    amountPaid: paid,
    status: status,
  );
}

/// Escenario del diseño: 1 terminada, 1 no asistió, 1 en juego y 2 próximas.
final designScenario = [
  reservation(
    id: 'done',
    startHour: 16,
    startMinute: 30,
    minutes: 90,
    total: 90000,
    paid: 90000,
    status: ReservationStatus.completed,
  ),
  reservation(
    id: 'noshow',
    startHour: 17,
    startMinute: 30,
    total: 80000,
    paid: 30000,
    status: ReservationStatus.noShow,
  ),
  reservation(
    id: 'live',
    startHour: 19,
    minutes: 90,
    total: 100000,
    paid: 40000,
    name: 'Valentina Dussán',
  ),
  reservation(id: 'next-paid', startHour: 19, startMinute: 30, minutes: 90),
  reservation(
    id: 'next-due',
    startHour: 21,
    minutes: 90,
    total: 160000,
    paid: 50000,
  ),
  reservation(
    id: 'cancelled',
    startHour: 20,
    status: ReservationStatus.cancelled,
  ),
];
