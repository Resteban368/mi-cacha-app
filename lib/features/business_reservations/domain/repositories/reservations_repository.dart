import '../../../../core/domain/entities/sport.dart';
import '../entities/availability.dart';
import '../entities/customer.dart';
import '../entities/new_reservation.dart';
import '../entities/reservation.dart';
import '../entities/reservation_query.dart';

/// Lanza `ReservationException` cuando la API rechaza la operación.
abstract interface class ReservationsRepository {
  /// Reservas del negocio para el día indicado (ignora la hora).
  Future<List<Reservation>> getReservationsForDay(DateTime day);

  /// Todas las reservas que cumplen [query], paginadas.
  Future<ReservationPage> listReservations(
    ReservationQuery query, {
    int page = 1,
    int pageSize = ReservationPage.defaultPageSize,
  });

  /// Turnos de [day] (día local) de las canchas reservables de [sport].
  Future<SportAvailability> getSportAvailability(Sport sport, DateTime day);

  /// Clientes por nombre, teléfono o cédula (máx. 20); sin texto, los
  /// más recientes.
  Future<List<Customer>> searchCustomers(String query);

  Future<Reservation> create(NewReservation reservation);

  Future<Reservation> getReservation(String id);

  Future<Reservation> cancel(String id, String reason);

  Future<Reservation> updateStatus(String id, ReservationStatus status);
}
