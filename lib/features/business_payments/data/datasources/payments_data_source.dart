import '../../../../core/utils/clock.dart';
import '../../domain/entities/new_payment.dart';
import '../../domain/entities/payment.dart';

abstract interface class PaymentsDataSource {
  Future<List<Payment>> getPayments();

  Future<Payment> updateStatus(
    String paymentId,
    PaymentStatus status, {
    String? rejectionReason,
  });

  Future<Payment> create(NewPayment payment);
}

/// Pagos de ejemplo en memoria mientras la API está en construcción.
/// Los cambios (aprobar, rechazar, crear) se conservan durante la sesión.
/// TODO: reemplazar por la API (HTTPS) + caché local para modo offline.
class FakePaymentsDataSource implements PaymentsDataSource {
  FakePaymentsDataSource(
    this._clock, {
    this.latency = const Duration(milliseconds: 500),
  });

  final Clock _clock;
  final Duration latency;
  List<Payment>? _payments;
  int _nextId = 100;

  List<Payment> get _store => _payments ??= _seed(_clock.now());

  static List<Payment> _seed(DateTime now) {
    DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));
    DateTime todayAt(int hour, [int minute = 0]) =>
        DateTime(now.year, now.month, now.day, hour, minute);

    return [
      Payment(
        id: 'p1',
        customerName: 'Valentina Dussán',
        amount: 60000,
        method: PaymentMethod.nequi,
        concept: PaymentConcept.saldo,
        reference: 'M4829310',
        courtName: 'Cancha Múltiple',
        reservationStart: todayAt(19),
        receivedAt: ago(4),
        status: PaymentStatus.pending,
      ),
      Payment(
        id: 'p2',
        customerName: 'Torneo Nocturno Caquetá',
        amount: 50000,
        method: PaymentMethod.bancolombiaQr,
        concept: PaymentConcept.anticipo,
        reference: '000184520',
        courtName: 'Sintética 1',
        reservationStart: todayAt(21),
        receivedAt: ago(26),
        status: PaymentStatus.pending,
      ),
      Payment(
        id: 'p3',
        customerName: 'Laura Restrepo',
        amount: 45000,
        method: PaymentMethod.daviplata,
        concept: PaymentConcept.anticipo,
        reference: 'DP-772014',
        courtName: 'Pádel 2',
        reservationStart: todayAt(20, 30).add(const Duration(days: 1)),
        receivedAt: ago(75),
        status: PaymentStatus.pending,
      ),
      Payment(
        id: 'p4',
        customerName: 'Camilo Méndez',
        amount: 100000,
        method: PaymentMethod.transferencia,
        concept: PaymentConcept.total,
        reference: 'TR-55102',
        courtName: 'Arena vóley playa',
        reservationStart: todayAt(19, 30),
        receivedAt: ago(180),
        status: PaymentStatus.approved,
      ),
      Payment(
        id: 'p5',
        customerName: 'Mateo Gómez',
        amount: 90000,
        method: PaymentMethod.efectivo,
        concept: PaymentConcept.total,
        courtName: 'Pádel 1',
        reservationStart: todayAt(16, 30),
        receivedAt: ago(240),
        status: PaymentStatus.approved,
        registeredByBusiness: true,
      ),
      Payment(
        id: 'p6',
        customerName: 'Andrés Felipe Castro',
        amount: 30000,
        method: PaymentMethod.nequi,
        concept: PaymentConcept.anticipo,
        reference: 'M1102938',
        courtName: 'Sintética 1',
        reservationStart: todayAt(17, 30),
        receivedAt: ago(60 * 26),
        status: PaymentStatus.rejected,
        rejectionReason: 'El comprobante no coincide con el valor.',
      ),
    ];
  }

  @override
  Future<List<Payment>> getPayments() async {
    await Future<void>.delayed(latency);
    return List.unmodifiable(
      [..._store]..sort((a, b) => b.receivedAt.compareTo(a.receivedAt)),
    );
  }

  @override
  Future<Payment> updateStatus(
    String paymentId,
    PaymentStatus status, {
    String? rejectionReason,
  }) async {
    await Future<void>.delayed(latency);
    final index = _store.indexWhere((p) => p.id == paymentId);
    if (index < 0) throw StateError('Pago no encontrado: $paymentId');
    final updated = _store[index].copyWith(
      status: status,
      rejectionReason: rejectionReason,
    );
    _store[index] = updated;
    return updated;
  }

  @override
  Future<Payment> create(NewPayment payment) async {
    await Future<void>.delayed(latency);
    final created = Payment(
      id: 'p${_nextId++}',
      customerName: payment.customerName.trim(),
      amount: payment.amount,
      method: payment.method,
      concept: payment.concept,
      reference: payment.reference?.trim(),
      note: payment.note?.trim(),
      receivedAt: _clock.now(),
      status: PaymentStatus.approved,
      registeredByBusiness: true,
    );
    _store.add(created);
    return created;
  }
}
