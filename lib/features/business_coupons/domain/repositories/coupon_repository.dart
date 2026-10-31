import '../entities/coupon.dart';

abstract interface class CouponRepository {
  Future<List<Coupon>> coupons();

  Future<Coupon> coupon(String id);

  Future<Coupon> save(CouponDraft draft);

  Future<Coupon> setActive(String id, {required bool isActive});

  Future<CouponCardPage> cards(
    String couponId, {
    required CouponCardStatus status,
    required int page,
  });

  Future<List<CustomerCoupon>> forCustomer(String customerId);

  Future<CouponRedemption> redeem({
    required String reservationId,
    required String cardId,
    int? courts,
  });
}
