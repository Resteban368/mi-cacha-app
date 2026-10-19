import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/sport.dart';
import 'customer.dart';

/// Dónde se reserva: una cancha elegida o la primera libre de un deporte.
sealed class CourtTarget extends Equatable {
  const CourtTarget();
}

/// La cancha elegida (`courtId`).
final class CourtById extends CourtTarget {
  const CourtById(this.courtId);

  final String courtId;

  @override
  List<Object?> get props => [courtId];
}

/// Varias canchas a la vez en la misma franja (`courtIds`, 2 a 3).
final class CourtsByIds extends CourtTarget {
  const CourtsByIds(this.courtIds);

  final List<String> courtIds;

  @override
  List<Object?> get props => [courtIds];
}

/// Cualquier cancha libre del deporte (`sport`): la asigna la API. Con
/// [courts] > 1, esa cantidad de canchas libres a la vez.
final class AnyCourtOfSport extends CourtTarget {
  const AnyCourtOfSport(this.sport, {this.courts = 1});

  final Sport sport;
  final int courts;

  @override
  List<Object?> get props => [sport, courts];
}

/// Pago que se registra al reservar.
class NewPayment extends Equatable {
  const NewPayment({
    required this.amount,
    required this.method,
    this.reference,
    this.note,
  });

  /// COP; mayor que 0 y sin superar el total.
  final int amount;

  /// `code` del catálogo de métodos de pago (p. ej. `NEQUI`).
  final String method;
  final String? reference;
  final String? note;

  @override
  List<Object?> get props => [amount, method, reference, note];
}

/// Datos para crear una reserva (entrada del caso de uso).
class NewReservation extends Equatable {
  const NewReservation({
    required this.target,
    required this.start,
    required this.slots,
    this.customerId,
    this.customer,
    this.customerDetail,
    this.contactNote,
    this.tag,
    this.isRecurring = false,
    this.discount = 0,
    this.payment,
  }) : assert(
         (customerId == null) != (customer == null),
         'Envía customerId o customer, uno de los dos',
       );

  static const maxSlots = 5;

  /// Canchas que se reservan a la vez en la misma franja.
  static const maxCourts = 3;
  static const maxDetail = 100;
  static const maxContactNote = 200;
  static const maxTag = 30;

  final CourtTarget target;

  /// `start` del turno tal como llegó de la disponibilidad.
  final String start;
  final int slots;
  final String? customerId;
  final NewCustomer? customer;
  final String? customerDetail;
  final String? contactNote;
  final String? tag;
  final bool isRecurring;
  final int discount;
  final NewPayment? payment;

  @override
  List<Object?> get props => [
    target,
    start,
    slots,
    customerId,
    customer,
    customerDetail,
    contactNote,
    tag,
    isRecurring,
    discount,
    payment,
  ];
}
