import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/sport.dart';
import '../../../business_payments/domain/entities/payment.dart';
import '../../../business_sales/domain/entities/sale.dart';
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

/// Cancha de una reserva de varias canchas.
class ReservationGroupCourt extends Equatable {
  const ReservationGroupCourt({
    required this.reservationId,
    required this.courtId,
    required this.courtName,
  });

  final String reservationId;
  final String courtId;
  final String courtName;

  @override
  List<Object?> get props => [reservationId, courtId, courtName];
}

/// Varias canchas reservadas a la vez en la misma franja: se pagan y se
/// cancelan juntas. Cada cancha llega como su propia [Reservation].
class ReservationGroup extends Equatable {
  const ReservationGroup({
    required this.id,
    required this.courts,
    required this.totalPrice,
    required this.amountPaid,
    this.consumptionsTotal = 0,
  });

  final String id;
  final List<ReservationGroupCourt> courts;

  /// Suma de las canchas, con el descuento.
  final int totalPrice;

  /// Consumos de todas las canchas del grupo.
  final int consumptionsTotal;
  final int amountPaid;

  /// Lo que se cobra: canchas más consumos.
  int get amountDue => totalPrice + consumptionsTotal;

  int get balance => (amountDue - amountPaid).clamp(0, amountDue);

  @override
  List<Object?> get props => [
    id,
    courts,
    totalPrice,
    consumptionsTotal,
    amountPaid,
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
    this.consumptionsTotal = 0,
    this.consumptions = const [],
    this.cancellationReason,
    this.cancelledAt,
    this.cancelledBy,
    this.group,
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

  /// Suma de los consumos activos (bebidas, snacks…) cargados a esta cancha.
  final int consumptionsTotal;

  /// Ventas cargadas a la reserva, también las anuladas (más antigua primero).
  final List<Sale> consumptions;
  final String? cancellationReason;
  final DateTime? cancelledAt;

  /// Nombre de quien canceló.
  final String? cancelledBy;

  /// Si es parte de una reserva de varias canchas.
  final ReservationGroup? group;

  /// Lo que se cobra de esta cancha: su valor más sus consumos.
  int get amountDue => totalPrice + consumptionsTotal;

  /// Saldo de esta cancha (para sumar por cancha). Para mostrar al cliente
  /// usa [displayBalance], que en un grupo es el de todas las canchas.
  int get balance => (amountDue - amountPaid).clamp(0, amountDue);

  /// Total (canchas y consumos), pagado y saldo que ve el negocio: los del
  /// grupo si lo hay (los pagos de un grupo quedan en su primera reserva).
  int get displayTotal => group?.amountDue ?? amountDue;

  /// Consumos que suma [displayTotal] (los del grupo si lo hay).
  int get displayConsumptions => group?.consumptionsTotal ?? consumptionsTotal;

  /// Si todavía se le pueden cargar consumos.
  bool get acceptsConsumptions =>
      status == ReservationStatus.confirmed ||
      status == ReservationStatus.completed;
  int get displayPaid => group?.amountPaid ?? amountPaid;
  int get displayBalance => group?.balance ?? balance;

  bool get isFullyPaid => displayBalance == 0;

  /// "Sintética 1" o, en un grupo, "Sintética 1 + Sintética 2".
  String get courtsLabel => switch (group) {
    final group? => group.courts.map((c) => c.courtName).join(' + '),
    null => courtName,
  };

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
    consumptionsTotal,
    consumptions,
    cancellationReason,
    cancelledAt,
    cancelledBy,
    group,
  ];
}
