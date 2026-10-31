import '../../../../core/usecase/usecase.dart';
import '../entities/coupon.dart';
import '../repositories/coupon_repository.dart';

class GetCoupons implements UseCase<List<Coupon>, NoParams> {
  const GetCoupons(this._repository);

  final CouponRepository _repository;

  @override
  Future<List<Coupon>> call(NoParams _) => _repository.coupons();
}

class GetCoupon implements UseCase<Coupon, String> {
  const GetCoupon(this._repository);

  final CouponRepository _repository;

  @override
  Future<Coupon> call(String id) => _repository.coupon(id);
}

class SaveCoupon implements UseCase<Coupon, CouponDraft> {
  const SaveCoupon(this._repository);

  final CouponRepository _repository;

  @override
  Future<Coupon> call(CouponDraft draft) {
    if (draft.name.trim().length < 2) {
      throw ArgumentError('Escribe el nombre del cupón.');
    }
    if (draft.rewardDescription.trim().length < 2) {
      throw ArgumentError('Describe el premio.');
    }
    if (draft.requiredReservations < 1 || draft.requiredReservations > 100) {
      throw ArgumentError('Las reservas a llenar deben ser de 1 a 100.');
    }
    if (draft.rewardType == CouponRewardType.percent) {
      final percent = draft.percent ?? 0;
      if (percent < 1 || percent > 100) {
        throw ArgumentError('El porcentaje debe ser de 1 a 100.');
      }
    }
    if (draft.maxRedemptions case final max? when max < 1) {
      throw ArgumentError('La cantidad a redimir debe ser al menos 1.');
    }
    return _repository.save(draft);
  }
}

typedef SetCouponActiveParams = ({String id, bool isActive});

class SetCouponActive implements UseCase<Coupon, SetCouponActiveParams> {
  const SetCouponActive(this._repository);

  final CouponRepository _repository;

  @override
  Future<Coupon> call(SetCouponActiveParams params) =>
      _repository.setActive(params.id, isActive: params.isActive);
}

typedef GetCouponCardsParams = ({
  String couponId,
  CouponCardStatus status,
  int page,
});

class GetCouponCards implements UseCase<CouponCardPage, GetCouponCardsParams> {
  const GetCouponCards(this._repository);

  final CouponRepository _repository;

  @override
  Future<CouponCardPage> call(GetCouponCardsParams params) => _repository.cards(
    params.couponId,
    status: params.status,
    page: params.page,
  );
}

class GetCustomerCoupons implements UseCase<List<CustomerCoupon>, String> {
  const GetCustomerCoupons(this._repository);

  final CouponRepository _repository;

  @override
  Future<List<CustomerCoupon>> call(String customerId) =>
      _repository.forCustomer(customerId);
}

typedef RedeemCouponParams = ({
  String reservationId,
  String cardId,
  int? courts,
});

class RedeemCoupon implements UseCase<CouponRedemption, RedeemCouponParams> {
  const RedeemCoupon(this._repository);

  final CouponRepository _repository;

  @override
  Future<CouponRedemption> call(RedeemCouponParams params) =>
      _repository.redeem(
        reservationId: params.reservationId,
        cardId: params.cardId,
        courts: params.courts,
      );
}
