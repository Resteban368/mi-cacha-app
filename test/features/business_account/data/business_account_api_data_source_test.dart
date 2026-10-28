import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:mi_cancha/features/business_account/data/datasources/business_account_api_data_source.dart';
import 'package:mi_cancha/features/business_account/domain/entities/password_change.dart';

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

  test('lee el módulo de Ventas; sin `modules` queda inactivo', () async {
    final adapter = FakeHttpAdapter(
      (_) => (
        200,
        {
          ...accountJson,
          'modules': {
            'sales': {'enabled': true, 'enabledAt': '2026-10-28T17:00:00.000Z'},
          },
        },
      ),
    );
    final account = await BusinessAccountApiDataSource(
      apiDio(adapter),
    ).getAccount();
    expect(account.salesModule.enabled, isTrue);
    expect(
      account.salesModule.enabledAt,
      DateTime.parse('2026-10-28T17:00:00.000Z').toLocal(),
    );

    adapter.handler = (_) => (200, accountJson);
    final old = await BusinessAccountApiDataSource(
      apiDio(adapter),
    ).getAccount();
    expect(old.salesModule.enabled, isFalse);
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

  group('cambiar contraseña', () {
    const change = PasswordChange(
      currentPassword: 'actual123',
      newPassword: 'nueva12345',
    );

    test('PUT /auth/password con las dos contraseñas; 204 es éxito', () async {
      final adapter = FakeHttpAdapter((_) => (204, null));
      await BusinessAccountApiDataSource(
        apiDio(adapter),
      ).changePassword(change);

      final request = adapter.requests.single;
      expect(request.method, 'PUT');
      expect(request.path, '/auth/password');
      final body = request.data is String
          ? jsonDecode(request.data as String)
          : request.data;
      expect(body, {
        'currentPassword': 'actual123',
        'newPassword': 'nueva12345',
      });
    });

    test('400 trae el mensaje de la API para el formulario', () async {
      final adapter = FakeHttpAdapter(
        (_) => (
          400,
          {
            'message': 'La contraseña actual no es correcta',
            'error': 'Bad Request',
            'statusCode': 400,
          },
        ),
      );
      await expectLater(
        BusinessAccountApiDataSource(apiDio(adapter)).changePassword(change),
        throwsA(
          isA<PasswordChangeException>()
              .having((e) => e.failure, 'falla', PasswordChangeFailure.rejected)
              .having(
                (e) => e.message,
                'mensaje',
                'La contraseña actual no es correcta',
              ),
        ),
      );
    });

    test('sin conexión', () async {
      final adapter = FakeHttpAdapter(offline);
      await expectLater(
        BusinessAccountApiDataSource(apiDio(adapter)).changePassword(change),
        throwsA(
          isA<PasswordChangeException>().having(
            (e) => e.failure,
            'falla',
            PasswordChangeFailure.network,
          ),
        ),
      );
    });

    test('500 es error del servidor', () async {
      final adapter = FakeHttpAdapter((_) => (500, {'statusCode': 500}));
      await expectLater(
        BusinessAccountApiDataSource(apiDio(adapter)).changePassword(change),
        throwsA(
          isA<PasswordChangeException>().having(
            (e) => e.failure,
            'falla',
            PasswordChangeFailure.server,
          ),
        ),
      );
    });
  });
}
