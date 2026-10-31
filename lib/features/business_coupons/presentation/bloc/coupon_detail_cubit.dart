import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/coupon.dart';
import '../../domain/usecases/coupon_usecases.dart';

enum CouponDetailLoad { loading, ready, failure }

final class CouponDetailState extends Equatable {
  const CouponDetailState({
    this.load = CouponDetailLoad.loading,
    this.coupon,
    this.status = CouponCardStatus.redeemed,
    this.cards = const [],
    this.total = 0,
    this.page = 1,
    this.cardsLoading = false,
    this.cardsFailed = false,
  });

  final CouponDetailLoad load;
  final Coupon? coupon;

  /// Pestaña elegida: redimidos, por redimir o en progreso.
  final CouponCardStatus status;
  final List<CouponCard> cards;
  final int total;
  final int page;
  final bool cardsLoading;
  final bool cardsFailed;

  bool get hasMore => cards.length < total;

  CouponDetailState copyWith({
    CouponDetailLoad? load,
    Coupon? coupon,
    CouponCardStatus? status,
    List<CouponCard>? cards,
    int? total,
    int? page,
    bool? cardsLoading,
    bool? cardsFailed,
  }) => CouponDetailState(
    load: load ?? this.load,
    coupon: coupon ?? this.coupon,
    status: status ?? this.status,
    cards: cards ?? this.cards,
    total: total ?? this.total,
    page: page ?? this.page,
    cardsLoading: cardsLoading ?? this.cardsLoading,
    cardsFailed: cardsFailed ?? this.cardsFailed,
  );

  @override
  List<Object?> get props => [
    load,
    coupon,
    status,
    cards,
    total,
    page,
    cardsLoading,
    cardsFailed,
  ];
}

/// Un cupón con sus tarjetas: quién redimió, a qué hora y cuándo se llenó cada
/// reserva.
class CouponDetailCubit extends Cubit<CouponDetailState> {
  CouponDetailCubit({
    required GetCoupon getCoupon,
    required GetCouponCards getCards,
  }) : _getCoupon = getCoupon,
       _getCards = getCards,
       super(const CouponDetailState());

  final GetCoupon _getCoupon;
  final GetCouponCards _getCards;

  Future<void> load(String id) async {
    emit(state.copyWith(load: CouponDetailLoad.loading));
    try {
      final coupon = await _getCoupon(id);
      if (isClosed) return;
      emit(state.copyWith(load: CouponDetailLoad.ready, coupon: coupon));
      await _loadCards(page: 1);
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(load: CouponDetailLoad.failure));
    }
  }

  Future<void> selectStatus(CouponCardStatus status) async {
    if (status == state.status) return;
    emit(state.copyWith(status: status, cards: const [], total: 0));
    await _loadCards(page: 1);
  }

  Future<void> retryCards() => _loadCards(page: state.page);

  Future<void> loadMore() async {
    if (state.cardsLoading || !state.hasMore) return;
    await _loadCards(page: state.page + 1);
  }

  Future<void> _loadCards({required int page}) async {
    final coupon = state.coupon;
    if (coupon == null) return;
    final status = state.status;
    emit(state.copyWith(cardsLoading: true, cardsFailed: false));
    try {
      final result = await _getCards((
        couponId: coupon.id,
        status: status,
        page: page,
      ));
      // Cambió de pestaña mientras cargaba: esta respuesta ya no aplica.
      if (isClosed || status != state.status) return;
      emit(
        state.copyWith(
          cards: page == 1 ? result.items : [...state.cards, ...result.items],
          total: result.total,
          page: page,
          cardsLoading: false,
        ),
      );
    } catch (_) {
      if (isClosed || status != state.status) return;
      emit(state.copyWith(cardsLoading: false, cardsFailed: true));
    }
  }
}
