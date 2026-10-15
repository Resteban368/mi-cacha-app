import '../../../../core/usecase/usecase.dart';
import '../entities/reservation.dart';
import '../repositories/reservations_repository.dart';

class GetDayReservations implements UseCase<List<Reservation>, DateTime> {
  const GetDayReservations(this._repository);

  final ReservationsRepository _repository;

  @override
  Future<List<Reservation>> call(DateTime day) =>
      _repository.getReservationsForDay(DateTime(day.year, day.month, day.day));
}
