import '../../../../core/domain/entities/sport.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/availability.dart';
import '../entities/customer.dart';
import '../entities/new_reservation.dart';
import '../entities/reservation.dart';
import '../entities/reservation_failure.dart';
import '../entities/reservation_query.dart';
import '../repositories/reservations_repository.dart';

typedef SportAvailabilityParams = ({Sport sport, DateTime day});

/// Turnos del día de todas las canchas reservables de un deporte.
class GetSportAvailability
    implements UseCase<SportAvailability, SportAvailabilityParams> {
  const GetSportAvailability(this._repository);

  final ReservationsRepository _repository;

  @override
  Future<SportAvailability> call(SportAvailabilityParams params) =>
      _repository.getSportAvailability(params.sport, params.day);
}

class SearchCustomers implements UseCase<List<Customer>, String> {
  const SearchCustomers(this._repository);

  final ReservationsRepository _repository;

  @override
  Future<List<Customer>> call(String query) =>
      _repository.searchCustomers(query);
}

class CreateReservation implements UseCase<Reservation, NewReservation> {
  const CreateReservation(this._repository);

  final ReservationsRepository _repository;

  /// Valida lo que la API rechazaría, con un mensaje claro, antes de
  /// enviarlo. La API recalcula el valor; el suyo es el que vale.
  @override
  Future<Reservation> call(NewReservation reservation) async {
    final error = validate(reservation);
    if (error != null) {
      throw ReservationException(ReservationFailure.invalid, message: error);
    }
    return _repository.create(reservation);
  }

  /// [subtotal] es la suma estimada de los turnos (para validar descuento
  /// y pago); si no se conoce, esas dos reglas las valida la API. Con
  /// "Cualquier cancha" es el valor más bajo posible, porque la API puede
  /// asignar una cancha más barata.
  static String? validate(NewReservation r, {int? subtotal}) {
    if (r.slots < 1 || r.slots > NewReservation.maxSlots) {
      return 'Elige entre 1 y ${NewReservation.maxSlots} turnos.';
    }
    if (r.customer?.error case final error?) return error;
    if ((r.customerDetail?.length ?? 0) > NewReservation.maxDetail) {
      return 'El detalle del cliente admite hasta '
          '${NewReservation.maxDetail} caracteres.';
    }
    if ((r.contactNote?.length ?? 0) > NewReservation.maxContactNote) {
      return 'La nota admite hasta ${NewReservation.maxContactNote} '
          'caracteres.';
    }
    if ((r.tag?.length ?? 0) > NewReservation.maxTag) {
      return 'La etiqueta admite hasta ${NewReservation.maxTag} caracteres.';
    }
    if (r.discount < 0) return 'El descuento no puede ser negativo.';
    final payment = r.payment;
    if (payment != null && payment.amount <= 0) {
      return 'Ingresa el valor del pago.';
    }
    if (subtotal != null) {
      if (r.discount > subtotal) {
        return 'El descuento no puede superar el valor de la reserva.';
      }
      if (payment != null && payment.amount > subtotal - r.discount) {
        return 'El pago no puede superar el total de la reserva.';
      }
    }
    return null;
  }
}

class GetReservation implements UseCase<Reservation, String> {
  const GetReservation(this._repository);

  final ReservationsRepository _repository;

  @override
  Future<Reservation> call(String id) => _repository.getReservation(id);
}

typedef CancelReservationParams = ({String id, String reason});

class CancelReservation
    implements UseCase<Reservation, CancelReservationParams> {
  const CancelReservation(this._repository);

  final ReservationsRepository _repository;

  static const minReason = 3;
  static const maxReason = 200;

  static String? validateReason(String reason) {
    final text = reason.trim();
    if (text.length < minReason) return 'Escribe el motivo (mínimo 3 letras).';
    if (text.length > maxReason) return 'Máximo $maxReason caracteres.';
    return null;
  }

  @override
  Future<Reservation> call(CancelReservationParams params) async {
    if (validateReason(params.reason) case final error?) {
      throw ReservationException(ReservationFailure.invalid, message: error);
    }
    return _repository.cancel(params.id, params.reason);
  }
}

typedef UpdateReservationStatusParams = ({String id, ReservationStatus status});

class UpdateReservationStatus
    implements UseCase<Reservation, UpdateReservationStatusParams> {
  const UpdateReservationStatus(this._repository);

  final ReservationsRepository _repository;

  /// Para cancelar se usa [CancelReservation] (pide el motivo).
  @override
  Future<Reservation> call(UpdateReservationStatusParams params) async {
    if (params.status == ReservationStatus.cancelled) {
      throw ArgumentError('Para cancelar usa CancelReservation');
    }
    return _repository.updateStatus(params.id, params.status);
  }
}

typedef ListReservationsParams = ({ReservationQuery query, int page});

/// Todas las reservas del negocio con filtros, de 20 en 20.
class ListReservations
    implements UseCase<ReservationPage, ListReservationsParams> {
  const ListReservations(this._repository);

  final ReservationsRepository _repository;

  @override
  Future<ReservationPage> call(ListReservationsParams params) =>
      _repository.listReservations(params.query, page: params.page);
}
