import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_account/data/datasources/business_account_api_data_source.dart';

import '../../../helpers/api_dio.dart';
import '../../../helpers/fake_http_adapter.dart';

void main() {
  // Respuesta real de GET /business/account.
  final accountJson = {
    'admin': {
      'fullName': 'Cliente dev',
      'email': 'resteban368@gmail.com',
      'phone': '3208806654',
      'roleLabel': 'Administrador del negocio',
      'verified': true,
    },
    'subscription': {
      'planName': 'Gratis',
      'monthlyPrice': 0,
      'since': '2026-10-14T16:22:02.545Z',
      'nextPayment': '2026-11-13T16:22:02.522Z',
      'courtLimit': 1,
      'courtsInUse': 0,
      'benefits': [
        {
          'title': 'Agenda digital',
          'detail': 'Gestiona las reservas de 1 cancha',
        },
      ],
      'isActive': true,
      'autoBilling': false,
    },
  };

  test('lee administrador y suscripción', () async {
    final adapter = FakeHttpAdapter((_) => (200, accountJson));
    final account = await BusinessAccountApiDataSource(
      apiDio(adapter),
    ).getAccount();

    expect(adapter.requests.single.path, '/business/account');
    expect(account.admin.fullName, 'Cliente dev');
    expect(account.admin.initials, 'CD');
    expect(account.admin.phone, '3208806654');
    final plan = account.subscription!;
    expect(plan.planName, 'Gratis');
    expect(plan.courtLimit, 1);
    expect(plan.freeCourtSlots, 1);
    expect(plan.since, DateTime.parse('2026-10-14T16:22:02.545Z').toLocal());
    expect(plan.benefits.single.title, 'Agenda digital');
  });

  test('sin plan y con contacto vacío', () async {
    final adapter = FakeHttpAdapter(
      (_) => (
        200,
        {
          'admin': {
            'fullName': 'Ana',
            'email': null,
            'phone': null,
            'roleLabel': 'Admin',
            'verified': false,
          },
          'subscription': null,
        },
      ),
    );
    final account = await BusinessAccountApiDataSource(
      apiDio(adapter),
    ).getAccount();

    expect(account.subscription, isNull);
    expect(account.admin.email, '');
  });
}
