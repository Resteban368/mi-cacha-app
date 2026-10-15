import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/sport.dart';
import '../../../business_payments/domain/entities/payment.dart';
import 'customer.dart';

/// Estado administrativo de la reserva (fijo en la plataforma).
enum ReservationStatus {
  confirmed('CONFIRMED'),
  completed('COMPLETED'),
  noShow('NO_SHOW'),
  cancelled('CANCELLED');

  const ReservationStatus(this.apiCode);

  /// Valor exacto que envía y recibe la API.
  final String apiCode;

  String get label => switch (this) {
    confirmed => 'Confirmada',
    completed => 'Jugada',
    noShow => 'No asistió',
    cancelled => 'Cancelada',
  };

  /// `null` si la API envía un estado desconocido.
  static ReservationStatus? fromApi(String? code) {
    if (code == null) return null;
    for (final status in values) {
      if (status.apiCode == code) return status;
    }
    return null;
  }
}

/// Pago asociado a una reserva.
class ReservationPayment extends Equatable {
  const ReservationPayment({
    required this.id,
    required this.amount,
    required this.method,
    required this.concept,
    required this.status,
    required this.receivedAt,
    this.reference,
  });

  final String id;
  final int amount;

  /// `code` del catálogo de métodos de pago.
  final String method;
  final PaymentConcept? concept;
  final PaymentStatus? status;
  final String? reference;
  final DateTime receivedAt;

  @override
  List<Object?> get props => [
    id,
    amount,
    method,
    concept,
    status,
    reference,
    receivedAt,
  ];
}

/// Momento de la reserva respecto a "ahora".
enum ReservationTiming { past, live, upcoming }

class Reservation extends Equatable {
  const Reservation({
    required this.id,
    required this.courtName,
    required this.sport,
    required this.start,
    required this.end,
    required this.customerName,
    required this.phone,
    required this.totalPrice,
    required this.amountPaid,
    required this.status,
    this.customerDetail,
    this.contactNote,
    this.tag,
    this.isRecurring = false,
    this.courtId,
    this.customer,
    int? subtotal,
    this.discount = 0,
    this.currency = 'COP',
    this.payments = const [],
    this.cancellationReason,
    this.cancelledAt,
    this.cancelledBy,
  }) : subtotal = subtotal ?? totalPrice;

  final String id;
  final String courtName;
  final Sport sport;
  final DateTime start;
  final DateTime end;

  /// Cliente u organizador (p. ej. "Torneo Nocturno Caquetá").
  final String customerName;

  /// Complemento junto al nombre (p. ej. "Club Vóley").
  final String? customerDetail;
  final String phone;

  /// Aclaración junto al teléfono (p. ej. "Org. Miller").
  final String? contactNote;

  /// Etiqueta destacada (sede, "Jueves recurrentes", ...).
  final String? tag;
  final bool isRecurring;

  /// Valores en pesos colombianos (COP), sin decimales.
  final int totalPrice;
  final int amountPaid;
  final ReservationStatus status;

  final String? courtId;

  /// `null` en reservas anteriores a la tabla de clientes.
  final Customer? customer;

  /// Valor según las tarifas, antes del descuento.
  final int subtotal;
  final int discount;
  final String currency;
  final List<ReservationPayment> payments;
  final String? cancellationReason;
  final DateTime? cancelledAt;

  /// Nombre de quien canceló.
  final String? cancelledBy;

  int get balance => (totalPrice - amountPaid).clamp(0, totalPrice);

  bool get isFullyPaid => balance == 0;

  Duration get duration => end.difference(start);

  /// Reservas que ya no se cobrarán ni jugarán.
  bool get isVoid =>
      status == ReservationStatus.noShow ||
      status == ReservationStatus.cancelled;

  ReservationTiming timingAt(DateTime now) {
    if (!now.isBefore(end)) return ReservationTiming.past;
    if (!now.isBefore(start)) return ReservationTiming.live;
    return ReservationTiming.upcoming;
  }

  @override
  List<Object?> get props => [
    id,
    courtName,
    sport,
    start,
    end,
    customerName,
    customerDetail,
    phone,
    contactNote,
    tag,
    isRecurring,
    totalPrice,
    amountPaid,
    status,
    courtId,
    customer,
    subtotal,
    discount,
    currency,
    payments,
    cancellationReason,
    cancelledAt,
    cancelledBy,
  ];
}
