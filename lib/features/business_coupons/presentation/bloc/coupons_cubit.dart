import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/media/image_upload.dart';
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
    required SetCouponImage setCouponImage,
    required RemoveCouponImage removeCouponImage,
  }) : _get = getCoupons,
       _save = saveCoupon,
       _setActive = setCouponActive,
       _setImage = setCouponImage,
       _removeImage = removeCouponImage,
       super(const CouponsState());

  final GetCoupons _get;
  final SaveCoupon _save;
  final SetCouponActive _setActive;
  final SetCouponImage _setImage;
  final RemoveCouponImage _removeImage;

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
  ///
  /// El cupón se guarda antes que la imagen: si ella falla, el cupón ya existe,
  /// así que no se reintenta el formulario (crearía otro) y se avisa en [warning].
  Future<({String? error, String? warning})> save(
    CouponDraft draft, {
    ImageUpload? image,
    bool removeImage = false,
  }) async {
    Coupon? saved;
    final error = await _apply(() async => saved = await _save(draft));
    final coupon = saved;
    if (error != null || coupon == null) return (error: error, warning: null);
    if (image == null && !removeImage) return (error: null, warning: null);
    final imageError = await _apply(
      () => image == null
          ? _removeImage(coupon.id)
          : _setImage((id: coupon.id, image: image)),
    );
    return (
      error: null,
      warning: imageError == null
          ? null
          : 'El cupón se guardó, pero no la imagen: $imageError',
    );
  }

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
    } on ImageUploadException catch (error) {
      return switch (error.error) {
        ImageUploadError.tooLarge => 'La imagen no puede superar 4 MB.',
        ImageUploadError.invalidType => 'La imagen debe ser JPG o PNG.',
      };
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
