import 'package:dio/dio.dart';

import '../../../../core/media/image_upload.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/coupon.dart';
import '../../domain/repositories/coupon_repository.dart';

/// Cupones del negocio en la API (`/business/coupons`).
class CouponsApiDataSource implements CouponRepository {
  const CouponsApiDataSource(this._dio);

  final Dio _dio;

  static const _path = '/business/coupons';
  static const _pageSize = 20;

  @override
  Future<List<Coupon>> coupons() async {
    final response = await apiCall(() => _dio.get<List<dynamic>>(_path));
    return [
      for (final item in response.data ?? const [])
        couponFromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<Coupon> coupon(String id) async {
    final response = await apiCall(
      () => _dio.get<Map<String, dynamic>>('$_path/$id'),
    );
    return couponFromJson(response.data!);
  }

  @override
  Future<Coupon> save(CouponDraft draft) async {
    final common = {
      'name': draft.name.trim(),
      'rewardDescription': draft.rewardDescription.trim(),
      'expiresOn': switch (draft.expiresOn) {
        final date? => dateOnly(date),
        null => null,
      },
      'maxRedemptions': draft.maxRedemptions,
    };
    final id = draft.id;
    final response = await apiCall(
      () => id == null
          ? _dio.post<Map<String, dynamic>>(
              _path,
              data: {
                ...common,
                'requiredReservations': draft.requiredReservations,
                'rewardType': _rewardTypeCode(draft.rewardType),
                if (draft.rewardType == CouponRewardType.percent)
                  'percent': draft.percent,
              },
            )
          : _dio.patch<Map<String, dynamic>>('$_path/$id', data: common),
    );
    return couponFromJson(response.data!);
  }

  @override
  Future<Coupon> setActive(String id, {required bool isActive}) async {
    final response = await apiCall(
      () => _dio.patch<Map<String, dynamic>>(
        '$_path/$id',
        data: {'isActive': isActive},
      ),
    );
    return couponFromJson(response.data!);
  }

  /// Multipart desde bytes (no `fromFile`) para que funcione también en web.
  @override
  Future<Coupon> setImage(String id, ImageUpload image) async {
    final form = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        image.bytes,
        filename: image.fileName,
        contentType: DioMediaType('image', image.isPng ? 'png' : 'jpeg'),
      ),
    });
    final response = await apiCall(
      () => _dio.put<Map<String, dynamic>>('$_path/$id/image', data: form),
    );
    return couponFromJson(response.data!);
  }

  @override
  Future<Coupon> removeImage(String id) async {
    final response = await apiCall(
      () => _dio.delete<Map<String, dynamic>>('$_path/$id/image'),
    );
    return couponFromJson(response.data!);
  }

  @override
  Future<void> delete(String id) async {
    await apiCall(() => _dio.delete<void>('$_path/$id'));
  }

  @override
  Future<CouponCardPage> cards(
    String couponId, {
    required CouponCardStatus status,
    required int page,
  }) async {
    final response = await apiCall(
      () => _dio.get<Map<String, dynamic>>(
        '$_path/$couponId/cards',
        queryParameters: {
          'status': _statusCode(status),
          'page': page,
          'pageSize': _pageSize,
        },
      ),
    );
    final json = response.data ?? const {};
    return (
      items: [
        for (final item in (json['items'] as List<dynamic>? ?? const []))
          _cardFromJson(item as Map<String, dynamic>),
      ],
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<List<CustomerCoupon>> forCustomer(String customerId) async {
    final response = await apiCall(
      () => _dio.get<List<dynamic>>('/business/customers/$customerId/coupons'),
    );
    return [
      for (final item in response.data ?? const [])
        _customerCouponFromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<CouponRedemption> redeem({
    required String reservationId,
    required String cardId,
    int? courts,
  }) async {
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(
        '/business/reservations/$reservationId/coupon-redemption',
        data: {'cardId': cardId, 'courts': ?courts},
      ),
    );
    final json = response.data!;
    return (
      amount: (json['amount'] as num).round(),
      courts: (json['courts'] as num?)?.toInt(),
      balance: (json['balance'] as num).round(),
    );
  }

  /// `2026-12-31`: el último día válido, sin hora.
  static String dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static Coupon couponFromJson(Map<String, dynamic> json) => Coupon(
    id: json['id'] as String,
    name: json['name'] as String,
    requiredReservations: (json['requiredReservations'] as num).toInt(),
    rewardType: json['rewardType'] == 'PERCENT'
        ? CouponRewardType.percent
        : CouponRewardType.freeCourt,
    percent: (json['percent'] as num?)?.toInt(),
    rewardDescription: json['rewardDescription'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
    expiresAt: _date(json['expiresAt']),
    maxRedemptions: (json['maxRedemptions'] as num?)?.toInt(),
    redeemedCount: (json['redeemedCount'] as num?)?.toInt() ?? 0,
    state: switch (json['state']) {
      'EXPIRED' => CouponState.expired,
      'EXHAUSTED' => CouponState.exhausted,
      'INACTIVE' => CouponState.inactive,
      _ => CouponState.active,
    },
    isActive: json['isActive'] as bool? ?? true,
  );

  static CouponCard _cardFromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>;
    return CouponCard(
      id: json['id'] as String,
      customerName: customer['name'] as String,
      customerPhone: customer['phone'] as String? ?? '',
      status: _statusFromCode(json['status']),
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      required: (json['required'] as num?)?.toInt() ?? 0,
      stamps: _stamps(json['stamps']),
      earnedAt: _date(json['earnedAt']),
      redeemedAt: _date(json['redeemedAt']),
      redeemedCourts: (json['redeemedCourts'] as num?)?.toInt(),
      redeemedAmount: (json['redeemedAmount'] as num?)?.round(),
    );
  }

  static CustomerCoupon _customerCouponFromJson(Map<String, dynamic> json) =>
      CustomerCoupon(
        coupon: couponFromJson(json['coupon'] as Map<String, dynamic>),
        cardId: json['cardId'] as String?,
        status: _statusFromCode(json['status']),
        completed: (json['completed'] as num?)?.toInt() ?? 0,
        required: (json['required'] as num?)?.toInt() ?? 0,
        stamps: _stamps(json['stamps']),
      );

  static List<CouponStamp> _stamps(Object? json) => [
    for (final item in (json as List<dynamic>? ?? const []))
      CouponStamp(
        playedAt: _date((item as Map<String, dynamic>)['playedAt'])!,
        stampedAt: _date(item['stampedAt'])!,
        courts: (item['courts'] as num?)?.toInt() ?? 1,
        courtNames: [
          for (final name in (item['courtNames'] as List<dynamic>? ?? const []))
            name as String,
        ],
        amount: (item['amount'] as num?)?.round() ?? 0,
      ),
  ];

  static DateTime? _date(Object? value) => switch (value) {
    final String text => DateTime.parse(text).toLocal(),
    _ => null,
  };

  static String _rewardTypeCode(CouponRewardType type) => switch (type) {
    CouponRewardType.freeCourt => 'FREE_COURT',
    CouponRewardType.percent => 'PERCENT',
  };

  static String _statusCode(CouponCardStatus status) => switch (status) {
    CouponCardStatus.inProgress => 'IN_PROGRESS',
    CouponCardStatus.earned => 'EARNED',
    CouponCardStatus.redeemed => 'REDEEMED',
  };

  static CouponCardStatus _statusFromCode(Object? code) => switch (code) {
    'EARNED' => CouponCardStatus.earned,
    'REDEEMED' => CouponCardStatus.redeemed,
    _ => CouponCardStatus.inProgress,
  };
}
