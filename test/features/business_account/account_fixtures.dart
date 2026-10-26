import 'package:mi_cancha/features/business_account/domain/entities/business_account.dart';

final account = BusinessAccount(
  admin: const AdminProfile(
    fullName: 'Carlos Rodríguez',
    email: 'carlos@elgolazo.co',
    phone: '+57 312 458 9201',
    roleLabel: 'Admin Pro',
    verified: true,
  ),
  subscription: Subscription(
    planName: 'Plan Básico',
    monthlyPrice: 79900,
    since: DateTime(2026, 9, 15),
    nextPayment: DateTime(2026, 10, 15),
    courtLimit: 5,
    courtsInUse: 3,
    nextPlanName: 'Pro',
    benefits: const [
      PlanBenefit(title: 'Hasta 5 canchas registradas', detail: 'Detalle 1'),
      PlanBenefit(title: 'Reservas ilimitadas', detail: 'Detalle 2'),
    ],
  ),
);
