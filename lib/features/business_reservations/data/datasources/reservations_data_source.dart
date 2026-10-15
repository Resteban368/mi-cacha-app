import '../../../../core/domain/entities/sport.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/availability.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/new_reservation.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/reservation_query.dart';

abstract interface class ReservationsDataSource {
  Future<List<Reservation>> getReservationsForDay(DateTime day);

  Future<Availability> getAvailability(String courtId, DateTime day);

  Future<ReservationPage> listReservations(
    ReservationQuery query, {
    required int page,
    required int pageSize,
  });

  Future<List<Customer>> searchCustomers(String query);

  Future<Reservation> create(NewReservation reservation);

  Future<Reservation> getReservation(String id);

  Future<Reservation> cancel(String id, String reason);

  Future<Reservation> updateStatus(String id, ReservationStatus status);
}

/// Datos de ejemplo mientras la API está en construcción.
///
/// Si se pide el día de hoy, los horarios se generan alrededor de la hora
/// actual para que siempre haya reservas pasadas, una en juego y próximas
/// (como en el diseño "Reservas de Hoy").
/// TODO: reemplazar por la API (HTTPS) + caché local para modo offline.
class FakeReservationsDataSource implements ReservationsDataSource {
  const FakeReservationsDataSource(
    this._clock, {
    this.latency = const Duration(milliseconds: 600),
  });

  final Clock _clock;
  final Duration latency;

  @override
  Future<List<Reservation>> getReservationsForDay(DateTime day) async {
    await Future<void>.delayed(latency);

    final now = _clock.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    // Ancla: ahora redondeado a 15 min (hoy) o 7:00 p. m. (otros días).
    final anchor = isToday
        ? DateTime(
            day.year,
            day.month,
            day.day,
            now.hour,
          ).add(Duration(minutes: now.minute - now.minute % 15))
        : DateTime(day.year, day.month, day.day, 19);

    DateTime at(int minutesFromAnchor) =>
        anchor.add(Duration(minutes: minutesFromAnchor));

    return [
      Reservation(
        id: 'r1',
        courtName: 'Pádel 1',
        sport: Sport.padel,
        start: at(-165),
        end: at(-75),
        customerName: 'Mateo Gómez',
        phone: '+57 311 482 9014',
        tag: 'Florencia',
        totalPrice: 90000,
        amountPaid: 90000,
        status: ReservationStatus.completed,
      ),
      Reservation(
        id: 'r2',
        courtName: 'Sintética 1',
        sport: Sport.futbol,
        start: at(-105),
        end: at(-45),
        customerName: 'Andrés Felipe Castro',
        phone: '+57 320 891 2234',
        totalPrice: 80000,
        amountPaid: 30000,
        status: ReservationStatus.noShow,
      ),
      Reservation(
        id: 'r3',
        courtName: 'Cancha Múltiple',
        sport: Sport.baloncesto,
        start: at(-15),
        end: at(75),
        customerName: 'Valentina Dussán',
        phone: '+57 314 559 1088',
        tag: 'Jueves recurrentes',
        isRecurring: true,
        totalPrice: 100000,
        amountPaid: 40000,
        status: ReservationStatus.confirmed,
      ),
      Reservation(
        id: 'r4',
        courtName: 'Arena vóley playa',
        sport: Sport.voleibol,
        start: at(15),
        end: at(105),
        customerName: 'Camilo Méndez',
        customerDetail: 'Club Vóley',
        phone: '+57 318 642 7701',
        totalPrice: 100000,
        amountPaid: 100000,
        status: ReservationStatus.confirmed,
      ),
      Reservation(
        id: 'r5',
        courtName: 'Sintética 1',
        sport: Sport.futbol,
        start: at(105),
        end: at(195),
        customerName: 'Torneo Nocturno Caquetá',
        phone: '+57 310 774 9120',
        contactNote: 'Org. Miller',
        totalPrice: 160000,
        amountPaid: 50000,
        status: ReservationStatus.confirmed,
      ),
    ];
  }

  // Solo la agenda tiene datos de ejemplo; el resto existe solo en la API.
  @override
  Future<ReservationPage> listReservations(
    ReservationQuery query, {
    required int page,
    required int pageSize,
  }) => throw UnimplementedError();

  @override
  Future<Availability> getAvailability(String courtId, DateTime day) =>
      throw UnimplementedError();

  @override
  Future<List<Customer>> searchCustomers(String query) =>
      throw UnimplementedError();

  @override
  Future<Reservation> create(NewReservation reservation) =>
      throw UnimplementedError();

  @override
  Future<Reservation> getReservation(String id) => throw UnimplementedError();

  @override
  Future<Reservation> cancel(String id, String reason) =>
      throw UnimplementedError();

  @override
  Future<Reservation> updateStatus(String id, ReservationStatus status) =>
      throw UnimplementedError();
}
