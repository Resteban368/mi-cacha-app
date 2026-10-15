import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/new_payment.dart';
import '../../domain/entities/payment.dart';
import 'payments_data_source.dart';

/// Pagos del negocio en la API (`/business/payments`).
class PaymentsApiDataSource implements PaymentsDataSource {
  const PaymentsApiDataSource(this._dio);

  final Dio _dio;

  static const _path = '/business/payments';

  @override
  Future<List<Payment>> getPayments() async {
    final response = await apiCall(() => _dio.get<List<dynamic>>(_path));
    return [
      for (final item in response.data ?? const [])
        fromJson(item as Map<String, dynamic>),
    ]..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
  }

  @override
  Future<Payment> updateStatus(
    String paymentId,
    PaymentStatus status, {
    String? rejectionReason,
  }) async {
    final response = await apiCall(
      () => switch (status) {
        PaymentStatus.approved => _dio.patch<Map<String, dynamic>>(
          '$_path/$paymentId/approve',
        ),
        PaymentStatus.rejected => _dio.patch<Map<String, dynamic>>(
          '$_path/$paymentId/reject',
          data: {'reason': rejectionReason ?? ''},
        ),
        PaymentStatus.pending ||
        PaymentStatus.refunded => throw ArgumentError.value(
          status,
          'status',
          'Un pago no puede volver a pendiente',
        ),
      },
    );
    return fromJson(response.data!);
  }

  @override
  Future<Payment> create(NewPayment payment) async {
    final reference = payment.reference?.trim();
    final note = payment.note?.trim();
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(
        _path,
        data: {
          'customerName': payment.customerName.trim(),
          'amount': payment.amount,
          'method': payment.method.apiCode,
          'concept': payment.concept.name.toUpperCase(),
          if (reference != null && reference.isNotEmpty) 'reference': reference,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      ),
    );
    return fromJson(response.data!);
  }

  static Payment fromJson(Map<String, dynamic> json) {
    final reservationStart = json['reservationStart'] as String?;
    return Payment(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      amount: (json['amount'] as num).toInt(),
      method: PaymentMethod.fromApi('${json['method']}'),
      concept: switch (json['concept']) {
        'ANTICIPO' => PaymentConcept.anticipo,
        'SALDO' => PaymentConcept.saldo,
        _ => PaymentConcept.total,
      },
      receivedAt: DateTime.parse(json['receivedAt'] as String).toLocal(),
      status: switch (json['status']) {
        'APPROVED' => PaymentStatus.approved,
        'REJECTED' => PaymentStatus.rejected,
        _ => PaymentStatus.pending,
      },
      courtName: json['courtName'] as String?,
      reservationStart: reservationStart == null
          ? null
          : DateTime.parse(reservationStart).toLocal(),
      reference: json['reference'] as String?,
      note: json['note'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      registeredByBusiness: json['registeredByBusiness'] as bool? ?? false,
    );
  }
}
