import '../../../../core/network/api_exception.dart';
import '../../domain/entities/availability.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/new_reservation.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/reservation_failure.dart';
import '../../domain/entities/reservation_query.dart';
import '../../domain/repositories/reservations_repository.dart';
import '../datasources/reservations_data_source.dart';

class ReservationsRepositoryImpl implements ReservationsRepository {
  const ReservationsRepositoryImpl(this._dataSource);

  final ReservationsDataSource _dataSource;

  @override
  Future<List<Reservation>> getReservationsForDay(DateTime day) =>
      _dataSource.getReservationsForDay(day);

  @override
  Future<ReservationPage> listReservations(
    ReservationQuery query, {
    int page = 1,
    int pageSize = ReservationPage.defaultPageSize,
  }) => _guard(
    () => _dataSource.listReservations(query, page: page, pageSize: pageSize),
  );

  @override
  Future<Availability> getAvailability(String courtId, DateTime day) =>
      _guard(() => _dataSource.getAvailability(courtId, day));

  @override
  Future<List<Customer>> searchCustomers(String query) =>
      _guard(() => _dataSource.searchCustomers(query));

  @override
  Future<Reservation> create(NewReservation reservation) =>
      _guard(() => _dataSource.create(reservation));

  @override
  Future<Reservation> getReservation(String id) =>
      _guard(() => _dataSource.getReservation(id));

  @override
  Future<Reservation> cancel(String id, String reason) =>
      _guard(() => _dataSource.cancel(id, reason));

  @override
  Future<Reservation> updateStatus(String id, ReservationStatus status) =>
      _guard(() => _dataSource.updateStatus(id, status));

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiException catch (error) {
      throw ReservationException(failureOf(error), message: error.message);
    }
  }

  /// Los 409 del backend no traen `code`: se distinguen por su mensaje.
  static ReservationFailure failureOf(ApiException error) {
    final message = error.message ?? '';
    return switch (error.kind) {
      ApiErrorKind.forbidden when error.code == 'SUBSCRIPTION_INACTIVE' =>
        ReservationFailure.subscriptionInactive,
      ApiErrorKind.conflict when message.contains('ya está reservada') =>
        ReservationFailure.slotTaken,
      ApiErrorKind.conflict when message.startsWith('La cancha está') =>
        ReservationFailure.courtNotBookable,
      ApiErrorKind.conflict when message.startsWith('El teléfono es de') =>
        ReservationFailure.customerConflict,
      ApiErrorKind.conflict => ReservationFailure.notCancellable,
      ApiErrorKind.badRequest => ReservationFailure.invalid,
      ApiErrorKind.notFound => ReservationFailure.notFound,
      ApiErrorKind.network => ReservationFailure.network,
      _ => ReservationFailure.server,
    };
  }
}
