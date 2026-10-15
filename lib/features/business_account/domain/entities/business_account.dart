import 'package:equatable/equatable.dart';

/// Administrador que inició sesión en el panel de negocio.
final class AdminProfile extends Equatable {
  const AdminProfile({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.roleLabel,
    this.verified = false,
  });

  final String fullName;
  final String email;
  final String phone;

  /// Rol visible en el perfil (p. ej. "Admin Pro").
  final String roleLabel;
  final bool verified;

  /// `Carlos Rodríguez` → `CR`.
  String get initials => fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word[0].toUpperCase())
      .join();

  @override
  List<Object?> get props => [fullName, email, phone, roleLabel, verified];
}

/// Beneficio incluido en el plan.
final class PlanBenefit extends Equatable {
  const PlanBenefit({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  List<Object?> get props => [title, detail];
}

/// Suscripción del negocio a Mi Cancha.
final class Subscription extends Equatable {
  const Subscription({
    required this.planName,
    required this.monthlyPrice,
    required this.since,
    required this.nextPayment,
    required this.courtLimit,
    required this.courtsInUse,
    required this.benefits,
    this.isActive = true,
    this.autoBilling = true,
  });

  final String planName;

  /// Precio mensual en pesos colombianos.
  final int monthlyPrice;
  final DateTime since;
  final DateTime nextPayment;
  final int courtLimit;
  final int courtsInUse;
  final List<PlanBenefit> benefits;
  final bool isActive;

  /// Cobro automático con tarjeta.
  final bool autoBilling;

  int get freeCourtSlots => (courtLimit - courtsInUse).clamp(0, courtLimit);

  /// Uso de canchas entre 0 y 1.
  double get usage =>
      courtLimit == 0 ? 0 : (courtsInUse / courtLimit).clamp(0, 1).toDouble();

  @override
  List<Object?> get props => [
    planName,
    monthlyPrice,
    since,
    nextPayment,
    courtLimit,
    courtsInUse,
    benefits,
    isActive,
    autoBilling,
  ];
}

/// Datos de la cuenta del administrador: perfil y suscripción.
final class BusinessAccount extends Equatable {
  const BusinessAccount({required this.admin, required this.subscription});

  final AdminProfile admin;

  /// `null` si el negocio aún no tiene plan.
  final Subscription? subscription;

  @override
  List<Object?> get props => [admin, subscription];
}
