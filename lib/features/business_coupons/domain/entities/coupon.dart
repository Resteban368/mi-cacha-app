import 'package:equatable/equatable.dart';

enum CouponRewardType { freeCourt, percent }

/// `active` suma reservas y se redime; `inactive` solo redime lo ya ganado;
/// `expired` y `exhausted` quedan cerrados.
enum CouponState { active, inactive, expired, exhausted }

enum CouponCardStatus { inProgress, earned, redeemed }

/// Cupón de fidelidad del negocio: cada [requiredReservations] reservas jugadas
/// y pagadas, el cliente gana un bono.
class Coupon extends Equatable {
  const Coupon({
    required this.id,
    required this.name,
    required this.requiredReservations,
    required this.rewardType,
    required this.rewardDescription,
    required this.redeemedCount,
    required this.state,
    required this.isActive,
    this.percent,
    this.imageUrl,
    this.expiresAt,
    this.maxRedemptions,
  });

  final String id;
  final String name;
  final int requiredReservations;
  final CouponRewardType rewardType;
  final int? percent;
  final String rewardDescription;

  /// `null` si no tiene imagen.
  final String? imageUrl;

  /// `null` si no vence.
  final DateTime? expiresAt;

  /// `null` si es ilimitado.
  final int? maxRedemptions;
  final int redeemedCount;
  final CouponState state;
  final bool isActive;

  bool get isClosed =>
      state == CouponState.expired || state == CouponState.exhausted;

  @override
  List<Object?> get props => [
    id,
    name,
    requiredReservations,
    rewardType,
    percent,
    rewardDescription,
    imageUrl,
    expiresAt,
    maxRedemptions,
    redeemedCount,
    state,
    isActive,
  ];
}

/// Datos del formulario; sin [id] crea un cupón. El tipo de premio, el porcentaje
/// y las reservas no se editan después de crearlo.
typedef CouponDraft = ({
  String? id,
  String name,
  int requiredReservations,
  CouponRewardType rewardType,
  int? percent,
  String rewardDescription,
  DateTime? expiresOn,
  int? maxRedemptions,
});

/// Una reserva jugada y pagada en la tarjeta de un cliente.
class CouponStamp extends Equatable {
  const CouponStamp({
    required this.playedAt,
    required this.stampedAt,
    required this.courts,
    required this.courtNames,
    required this.amount,
  });

  final DateTime playedAt;

  /// Cuándo se llenó esta casilla de la tarjeta.
  final DateTime stampedAt;
  final int courts;
  final List<String> courtNames;
  final int amount;

  @override
  List<Object?> get props => [playedAt, stampedAt, courts, courtNames, amount];
}

/// Tarjeta de un cliente en un cupón, con su historial.
class CouponCard extends Equatable {
  const CouponCard({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.completed,
    required this.required,
    required this.stamps,
    this.earnedAt,
    this.redeemedAt,
    this.redeemedCourts,
    this.redeemedAmount,
  });

  final String id;
  final String customerName;
  final String customerPhone;
  final CouponCardStatus status;
  final int completed;
  final int required;
  final List<CouponStamp> stamps;
  final DateTime? earnedAt;
  final DateTime? redeemedAt;
  final int? redeemedCourts;
  final int? redeemedAmount;

  @override
  List<Object?> get props => [
    id,
    customerName,
    customerPhone,
    status,
    completed,
    required,
    stamps,
    earnedAt,
    redeemedAt,
    redeemedCourts,
    redeemedAmount,
  ];
}

/// Una página de tarjetas del cupón.
typedef CouponCardPage = ({List<CouponCard> items, int total});

/// Avance de un cliente en un cupón, para redimir al cobrar.
class CustomerCoupon extends Equatable {
  const CustomerCoupon({
    required this.coupon,
    required this.status,
    required this.completed,
    required this.required,
    required this.stamps,
    this.cardId,
  });

  final Coupon coupon;
  final String? cardId;
  final CouponCardStatus status;
  final int completed;
  final int required;
  final List<CouponStamp> stamps;

  @override
  List<Object?> get props => [
    coupon,
    cardId,
    status,
    completed,
    required,
    stamps,
  ];
}

/// Resultado de redimir un bono en una reserva.
typedef CouponRedemption = ({int amount, int? courts, int balance});
