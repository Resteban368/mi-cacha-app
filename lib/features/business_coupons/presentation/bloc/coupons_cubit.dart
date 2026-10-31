import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/coupon.dart';
import '../../domain/usecases/coupon_usecases.dart';

enum CouponsLoad { loading, ready, failure }

final class CouponsState extends Equatable {
  const CouponsState({
    this.load = CouponsLoad.loading,
    this.coupons = const [],
  });

  final CouponsLoad load;

  /// Del más reciente al más antiguo.
  final List<Coupon> coupons;

  CouponsState copyWith({CouponsLoad? load, List<Coupon>? coupons}) =>
      CouponsState(load: load ?? this.load, coupons: coupons ?? this.coupons);

  @override
  List<Object?> get props => [load, coupons];
}

/// Cupones del negocio: crear, editar y activar/desactivar.
class CouponsCubit extends Cubit<CouponsState> {
  CouponsCubit({
    required GetCoupons getCoupons,
    required SaveCoupon saveCoupon,
    required SetCouponActive setCouponActive,
  }) : _get = getCoupons,
       _save = saveCoupon,
       _setActive = setCouponActive,
       super(const CouponsState());

  final GetCoupons _get;
  final SaveCoupon _save;
  final SetCouponActive _setActive;

  Future<void> load() async {
    emit(state.copyWith(load: CouponsLoad.loading));
    try {
      final coupons = await _get(const NoParams());
      if (isClosed) return;
      emit(state.copyWith(load: CouponsLoad.ready, coupons: coupons));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(load: CouponsLoad.failure));
    }
  }

  /// Crea o edita. Devuelve el error para mostrar, o `null` si se guardó.
  Future<String?> save(CouponDraft draft) => _apply(() => _save(draft));

  Future<String?> setActive(Coupon coupon, bool isActive) =>
      _apply(() => _setActive((id: coupon.id, isActive: isActive)));

  Future<String?> _apply(Future<Coupon> Function() request) async {
    try {
      final saved = await request();
      if (isClosed) return null;
      final exists = state.coupons.any((c) => c.id == saved.id);
      emit(
        state.copyWith(
          coupons: exists
              ? [for (final c in state.coupons) c.id == saved.id ? saved : c]
              : [saved, ...state.coupons],
        ),
      );
      return null;
    } on ArgumentError catch (error) {
      return '${error.message}';
    } on ApiException catch (error) {
      return switch (error.kind) {
        ApiErrorKind.network =>
          'Sin conexión. Revisa tu internet e intenta de nuevo.',
        ApiErrorKind.forbidden ||
        ApiErrorKind.conflict ||
        ApiErrorKind.badRequest =>
          error.message ?? 'No se pudo guardar el cupón.',
        _ => 'No se pudo guardar el cupón. Intenta de nuevo.',
      };
    } catch (_) {
      return 'No se pudo guardar el cupón. Intenta de nuevo.';
    }
  }
}
