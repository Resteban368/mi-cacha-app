import 'package:equatable/equatable.dart';

/// Medios de pago usados en Colombia.
enum PaymentMethod {
  efectivo('EFECTIVO', requiresReference: false),
  breB('BRE_B', requiresReference: true),
  nequi('NEQUI', requiresReference: true),
  daviplata('DAVIPLATA', requiresReference: true),
  bancolombiaQr('BANCOLOMBIA_QR', requiresReference: true),
  transferencia('TRANSFERENCIA', requiresReference: true),

  /// Código del catálogo que la app aún no conoce (solo para mostrar).
  otro(null, requiresReference: false);

  const PaymentMethod(this.apiCode, {this.requiresReference = false});

  /// Código del catálogo de la API; `null` en [otro].
  final String? apiCode;

  /// Si este método de pago exige referencia bancaria / comprobante.
  final bool requiresReference;

  /// Medios que se pueden elegir al registrar un pago.
  static List<PaymentMethod> get selectable =>
      values.where((method) => method.apiCode != null).toList();

  static PaymentMethod fromApi(String code) =>
      values.firstWhere((method) => method.apiCode == code, orElse: () => otro);
}

/// A qué corresponde el pago dentro de la reserva (fijo en la plataforma).
enum PaymentConcept {
  anticipo('ANTICIPO'),
  saldo('SALDO'),
  total('TOTAL');

  const PaymentConcept(this.apiCode);

  /// Valor exacto que envía y recibe la API.
  final String apiCode;

  static PaymentConcept? fromApi(String? code) {
    if (code == null) return null;
    for (final concept in values) {
      if (concept.apiCode == code) return concept;
    }
    return null;
  }
}

/// Estado de validación del pago (fijo en la plataforma).
enum PaymentStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED'),

  /// Devuelto al cancelar la reserva.
  refunded('REFUNDED');

  /// Estados que se validan en la pantalla de Pagos (sin devoluciones).
  static const tabs = [pending, approved, rejected];

  const PaymentStatus(this.apiCode);

  /// Valor exacto que envía y recibe la API.
  final String apiCode;

  static PaymentStatus? fromApi(String? code) {
    if (code == null) return null;
    for (final status in values) {
      if (status.apiCode == code) return status;
    }
    return null;
  }
}

class Payment extends Equatable {
  const Payment({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.method,
    required this.concept,
    required this.receivedAt,
    required this.status,
    this.courtName,
    this.reservationStart,
    this.reference,
    this.note,
    this.rejectionReason,
    this.registeredByBusiness = false,
  });

  final String id;
  final String customerName;

  /// Valor en pesos colombianos (COP), sin decimales.
  final int amount;
  final PaymentMethod method;
  final PaymentConcept concept;
  final DateTime receivedAt;
  final PaymentStatus status;

  /// Reserva asociada (si el pago viene de una reserva).
  final String? courtName;
  final DateTime? reservationStart;

  /// Referencia/número de transacción (transferencias y billeteras).
  final String? reference;
  final String? note;
  final String? rejectionReason;

  /// `true` si lo registró el negocio (p. ej. efectivo en taquilla);
  /// `false` si lo envió el jugador y requiere validación.
  final bool registeredByBusiness;

  Payment copyWith({PaymentStatus? status, String? rejectionReason}) => Payment(
    id: id,
    customerName: customerName,
    amount: amount,
    method: method,
    concept: concept,
    receivedAt: receivedAt,
    status: status ?? this.status,
    courtName: courtName,
    reservationStart: reservationStart,
    reference: reference,
    note: note,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    registeredByBusiness: registeredByBusiness,
  );

  @override
  List<Object?> get props => [
    id,
    customerName,
    amount,
    method,
    concept,
    receivedAt,
    status,
    courtName,
    reservationStart,
    reference,
    note,
    rejectionReason,
    registeredByBusiness,
  ];
}
