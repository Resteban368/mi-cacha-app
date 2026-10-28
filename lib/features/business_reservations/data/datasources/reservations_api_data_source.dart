import 'package:dio/dio.dart';

import '../../../../core/domain/entities/sport.dart';
import '../../../../core/network/api_exception.dart';
import '../../../business_payments/domain/entities/payment.dart';
import '../../../business_sales/data/datasources/sales_api_data_source.dart';
import '../../domain/entities/availability.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/new_reservation.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/entities/reservation_query.dart';
import 'reservations_data_source.dart';

/// Reservas del negocio en la API (`/business/reservations`, la
/// disponibilidad por deporte y los clientes).
class ReservationsApiDataSource implements ReservationsDataSource {
  const ReservationsApiDataSource(this._dio);

  final Dio _dio;

  static const _path = '/business/reservations';

  @override
  Future<List<Reservation>> getReservationsForDay(DateTime day) async {
    final response = await apiCall(
      () => _dio.get<List<dynamic>>(
        _path,
        queryParameters: {'date': dayParam(day)},
      ),
    );
    return [
      for (final item in response.data ?? const [])
        fromJson(item as Map<String, dynamic>),
    ]..sort((a, b) => a.start.compareTo(b.start));
  }

  /// Sin `date` la API devuelve todas las reservas paginadas
  /// (`{items, total, page, pageSize}`), de la más reciente a la más antigua.
  @override
  Future<ReservationPage> listReservations(
    ReservationQuery query, {
    required int page,
    required int pageSize,
  }) async {
    final search = query.search.trim();
    final response = await apiCall(
      () => _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search.isNotEmpty) 'search': search,
          'status': ?query.status?.apiCode,
          'courtId': ?query.courtId,
          'customerId': ?query.customerId,
          if (query.from case final from?) 'from': dayParam(from),
          if (query.to case final to?) 'to': dayParam(to),
        },
      ),
    );
    final json = response.data!;
    return ReservationPage(
      items: [
        for (final item in (json['items'] as List<dynamic>? ?? const []))
          fromJson(item as Map<String, dynamic>),
      ],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? page,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? pageSize,
    );
  }

  @override
  Future<SportAvailability> getSportAvailability(
    Sport sport,
    DateTime day,
  ) async {
    final response = await apiCall(
      () => _dio.get<Map<String, dynamic>>(
        '/business/availability',
        queryParameters: {'date': dayParam(day), 'sport': sport.apiCode},
      ),
    );
    final json = response.data!;
    return SportAvailability(
      date: json['date'] as String,
      sport: Sport.fromApi(json['sport'] as String?) ?? sport,
      maxSlots: (json['maxSlots'] as num?)?.toInt() ?? NewReservation.maxSlots,
      courts: [
        for (final item in (json['courts'] as List<dynamic>? ?? const []))
          _courtSlots(item as Map<String, dynamic>, sport),
      ],
    );
  }

  @override
  Future<List<Customer>> searchCustomers(String query) async {
    final search = query.trim();
    final response = await apiCall(
      () => _dio.get<List<dynamic>>(
        '/business/customers',
        queryParameters: {if (search.isNotEmpty) 'search': search},
      ),
    );
    return [
      for (final item in response.data ?? const [])
        _customer(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<Reservation> create(NewReservation reservation) async {
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(_path, data: toJson(reservation)),
    );
    return fromJson(response.data!);
  }

  @override
  Future<Reservation> getReservation(String id) async {
    final response = await apiCall(
      () => _dio.get<Map<String, dynamic>>('$_path/$id'),
    );
    return fromJson(response.data!);
  }

  @override
  Future<Reservation> cancel(String id, String reason) async {
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(
        '$_path/$id/cancel',
        data: {'reason': reason.trim()},
      ),
    );
    return fromJson(response.data!);
  }

  @override
  Future<Reservation> updateStatus(String id, ReservationStatus status) async {
    final response = await apiCall(
      () => _dio.patch<Map<String, dynamic>>(
        '$_path/$id/status',
        data: {'status': status.apiCode},
      ),
    );
    return fromJson(response.data!);
  }

  /// `2026-10-14`: el día calendario que se ve en la app.
  static String dayParam(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static String? _text(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static Map<String, dynamic> toJson(NewReservation r) {
    final customer = r.customer;
    final payment = r.payment;
    return {
      ...switch (r.target) {
        CourtById(:final courtId) => {'courtId': courtId},
        CourtsByIds(:final courtIds) => {'courtIds': courtIds},
        AnyCourtOfSport(:final sport, :final courts) => {
          'sport': sport.apiCode,
          if (courts > 1) 'courts': courts,
        },
      },
      // Tal como llegó en la disponibilidad.
      'start': r.start,
      'slots': r.slots,
      'customerId': ?r.customerId,
      if (customer != null)
        'customer': {
          'name': customer.name.trim(),
          'phone': customer.phone.trim(),
          'documentId': customer.documentId.trim(),
        },
      'customerDetail': ?_text(r.customerDetail),
      'contactNote': ?_text(r.contactNote),
      'tag': ?_text(r.tag),
      'isRecurring': r.isRecurring,
      if (r.discount > 0) 'discount': r.discount,
      if (payment != null)
        'payment': {
          'amount': payment.amount,
          'method': payment.method,
          'reference': ?_text(payment.reference),
          'note': ?_text(payment.note),
        },
    };
  }

  static int _money(Object? value) => (value as num? ?? 0).round();

  static CourtSlots _courtSlots(Map<String, dynamic> json, Sport sport) {
    final court = json['court'] as Map<String, dynamic>;
    final slots = [
      for (final slot in (json['slots'] as List<dynamic>? ?? const []))
        _slot(slot as Map<String, dynamic>),
    ];
    return CourtSlots(
      court: AvailabilityCourt(
        id: court['id'] as String,
        name: court['name'] as String,
        sport: Sport.fromApi(court['sport'] as String?) ?? sport,
        isCovered: court['isCovered'] as bool? ?? false,
        slotDuration: (court['slotDuration'] as num).toInt(),
        currency: court['currency'] as String? ?? 'COP',
        photoUrl: court['photoUrl'] as String?,
      ),
      availableCount:
          (json['availableCount'] as num?)?.toInt() ??
          slots.where((s) => s.isAvailable).length,
      slots: slots,
    );
  }

  static Slot _slot(Map<String, dynamic> json) {
    final start = json['start'] as String;
    return Slot(
      startIso: start,
      start: DateTime.parse(start).toLocal(),
      end: DateTime.parse(json['end'] as String).toLocal(),
      status: SlotStatus.fromApi(json['status'] as String?),
      price: _money(json['price']),
    );
  }

  static Customer _customer(Map<String, dynamic> json) => Customer(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String? ?? '',
    documentId: json['documentId'] as String? ?? '',
  );

  static ReservationPayment _payment(Map<String, dynamic> json) =>
      ReservationPayment(
        id: json['id'] as String,
        amount: _money(json['amount']),
        method: json['method'] as String? ?? 'EFECTIVO',
        concept: PaymentConcept.fromApi(json['concept'] as String?),
        status: PaymentStatus.fromApi(json['status'] as String?),
        reference: json['reference'] as String?,
        receivedAt: DateTime.parse(json['receivedAt'] as String).toLocal(),
      );

  static Reservation fromJson(Map<String, dynamic> json) => Reservation(
    id: json['id'] as String,
    courtId: json['courtId'] as String?,
    courtName: json['courtName'] as String,
    sport: Sport.fromApi(json['sport'] as String?) ?? Sport.futbol,
    start: DateTime.parse(json['start'] as String).toLocal(),
    end: DateTime.parse(json['end'] as String).toLocal(),
    customer: switch (json['customer']) {
      final Map<String, dynamic> customer => _customer(customer),
      _ => null,
    },
    customerName: json['customerName'] as String,
    customerDetail: json['customerDetail'] as String?,
    phone: json['phone'] as String? ?? '',
    contactNote: json['contactNote'] as String?,
    tag: json['tag'] as String?,
    isRecurring: json['isRecurring'] as bool? ?? false,
    subtotal: json.containsKey('subtotal') ? _money(json['subtotal']) : null,
    discount: _money(json['discount']),
    totalPrice: _money(json['totalPrice']),
    currency: json['currency'] as String? ?? 'COP',
    amountPaid: _money(json['amountPaid']),
    payments: [
      for (final item in (json['payments'] as List<dynamic>? ?? const []))
        _payment(item as Map<String, dynamic>),
    ],
    consumptionsTotal: _money(json['consumptionsTotal']),
    consumptions: [
      for (final item in (json['consumptions'] as List<dynamic>? ?? const []))
        SalesApiDataSource.saleFromJson(item as Map<String, dynamic>),
    ],
    status:
        ReservationStatus.fromApi(json['status'] as String?) ??
        ReservationStatus.confirmed,
    cancellationReason: json['cancellationReason'] as String?,
    cancelledAt: switch (json['cancelledAt']) {
      final String at => DateTime.parse(at).toLocal(),
      _ => null,
    },
    cancelledBy: json['cancelledBy'] as String?,
    group: switch (json['group']) {
      final Map<String, dynamic> group => _group(group),
      _ => null,
    },
  );

  static ReservationGroup _group(Map<String, dynamic> json) => ReservationGroup(
    id: json['id'] as String,
    courts: [
      for (final item in (json['courts'] as List<dynamic>? ?? const []))
        if (item case {
          'reservationId': final String reservationId,
          'courtId': final String courtId,
          'courtName': final String courtName,
        })
          ReservationGroupCourt(
            reservationId: reservationId,
            courtId: courtId,
            courtName: courtName,
          ),
    ],
    totalPrice: _money(json['totalPrice']),
    consumptionsTotal: _money(json['consumptionsTotal']),
    amountPaid: _money(json['amountPaid']),
  );
}
