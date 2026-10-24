import '../../domain/entities/business_account.dart';
import '../../domain/entities/password_change.dart';

abstract interface class BusinessAccountDataSource {
  Future<BusinessAccount> getAccount();

  Future<void> changePassword(PasswordChange change);
}

/// Datos de ejemplo del diseño "Mi Cuenta / Ajustes" mientras no exista la
/// API de cuentas y suscripciones.
// TODO: reemplazar por la API real (perfil del admin y suscripción).
class FakeBusinessAccountDataSource implements BusinessAccountDataSource {
  FakeBusinessAccountDataSource({
    this.latency = const Duration(milliseconds: 400),
  });

  final Duration latency;

  static final account = BusinessAccount(
    admin: const AdminProfile(
      fullName: 'Carlos Rodríguez',
      email: 'carlos.rodriguez@elgolazo.com.co',
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
      // TODO: tomar el número real de canchas cuando exista la sección Canchas.
      courtsInUse: 3,
      benefits: const [
        PlanBenefit(
          title: 'Hasta 5 canchas registradas',
          detail:
              'Compatible con fútbol sintético, pádel, tenis, básquetbol y '
              'voleibol.',
        ),
        PlanBenefit(
          title: 'Reservas ilimitadas sin comisiones',
          detail:
              'Sin porcentajes retenidos ni cobros extra por turno agendado.',
        ),
        PlanBenefit(
          title: 'Agenda digital en tiempo real',
          detail:
              'Historial de clientes, estados de pago (seña/saldo) y bloqueos '
              'rápidos.',
        ),
        PlanBenefit(
          title: 'Resumen de caja y reportes en PDF',
          detail:
              'Cierre diario de ingresos automáticos y confirmaciones con un '
              'toque.',
        ),
      ],
    ),
  );

  @override
  Future<BusinessAccount> getAccount() async {
    await Future<void>.delayed(latency);
    return account;
  }

  @override
  Future<void> changePassword(PasswordChange change) =>
      Future<void>.delayed(latency);
}
