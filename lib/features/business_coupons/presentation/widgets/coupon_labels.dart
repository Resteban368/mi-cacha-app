import '../../../../core/utils/formatters.dart';
import '../../domain/entities/coupon.dart';

/// `3 de 50 redimidos` o `3 redimidos · ilimitado`.
String couponRedemptionsLabel(Coupon coupon) => switch (coupon.maxRedemptions) {
  final max? => '${coupon.redeemedCount} de $max redimidos',
  null => '${coupon.redeemedCount} redimidos · ilimitado',
};

String couponExpiryLabel(Coupon coupon) => switch (coupon.expiresAt) {
  final date? => 'Hasta el ${AppFormatters.mediumDate(date)}',
  null => 'No vence',
};

String couponStateLabel(CouponState state) => switch (state) {
  CouponState.active => 'Activo',
  CouponState.inactive => 'Pausado',
  CouponState.expired => 'Vencido',
  CouponState.exhausted => 'Agotado',
};

String couponRewardTypeLabel(Coupon coupon) => switch (coupon.rewardType) {
  CouponRewardType.freeCourt => 'Cancha gratis',
  CouponRewardType.percent => '${coupon.percent ?? 0}% de descuento',
};

/// `15 sep. 2026, 6:30 p. m.`
String couponDateTime(DateTime date) =>
    '${AppFormatters.mediumDate(date)}, ${AppFormatters.time(date)}';
