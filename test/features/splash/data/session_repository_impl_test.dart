import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/network/api_client.dart';
import 'package:mi_cancha/core/session/session.dart';
import 'package:mi_cancha/core/session/session_manager.dart';
import 'package:mi_cancha/core/session/session_storage.dart';
import 'package:mi_cancha/features/auth/domain/entities/user_role.dart';
import 'package:mi_cancha/features/splash/data/repositories/session_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_adapter.dart';

class _MockStorage extends Mock implements SessionStorage {}

void main() {
  const admin = Session(
    accessToken: 'tok',
    role: 'ADMIN_NEGOCIO',
    displayName: 'Cliente dev',
  );

  late _MockStorage storage;
  late SessionManager session;
  late FakeHttpAdapter adapter;
  late SessionRepositoryImpl repository;

  setUp(() {
    storage = _MockStorage();
    when(() => storage.read()).thenAnswer((_) async => admin);
    when(() => storage.clear()).thenAnswer((_) async {});
    session = SessionManager(storage);
    adapter = FakeHttpAdapter(
      (_) => (200, {'id': 'u1', 'displayName': 'x', 'role': 'ADMIN_NEGOCIO'}),
    );
    final Dio dio = buildApiClient(session)..httpClientAdapter = adapter;
    repository = SessionRepositoryImpl(
      session,
      dio,
      verifyTimeout: const Duration(milliseconds: 200),
    );
  });

  test('sin sesión guardada no llama a la API', () async {
    when(() => storage.read()).thenAnswer((_) async => null);
    expect(await repository.activeRole(), isNull);
    expect(adapter.requests, isEmpty);
  });

  test('token válido: usa el rol que confirma /auth/me', () async {
    expect(await repository.activeRole(), UserRole.adminNegocio);
    final request = adapter.requests.single;
    expect(request.path, '/auth/me');
    expect(request.headers['Authorization'], 'Bearer tok');
  });

  test('token vencido (401): sin rol y la sesión queda cerrada', () async {
    adapter.handler = (_) => (401, {'message': 'Token inválido o expirado'});

    expect(await repository.activeRole(), isNull);
    expect(session.current, isNull);
    expect(session.consumeExpired(), isTrue);
  });

  test('sin conexión confía en la sesión guardada (offline)', () async {
    adapter.handler = offline;
    expect(await repository.activeRole(), UserRole.adminNegocio);
    expect(session.current, admin);
  });

  test('error del servidor también usa la sesión guardada', () async {
    adapter.handler = (_) => (503, null);
    expect(await repository.activeRole(), UserRole.adminNegocio);
  });

  test('storage corrupto se trata como sin sesión', () async {
    when(() => storage.read()).thenThrow(Exception('corrupt'));
    expect(await repository.activeRole(), isNull);
  });
}
