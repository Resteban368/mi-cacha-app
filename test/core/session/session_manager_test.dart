import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/session/session.dart';
import 'package:mi_cancha/core/session/session_manager.dart';
import 'package:mi_cancha/core/session/session_storage.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements SessionStorage {}

const admin = Session(
  accessToken: 'tok',
  role: 'ADMIN_NEGOCIO',
  displayName: 'Andrés Gómez',
);

void main() {
  setUpAll(() => registerFallbackValue(admin));

  late _MockStorage storage;
  late SessionManager manager;
  var notifications = 0;

  setUp(() {
    storage = _MockStorage();
    when(() => storage.read()).thenAnswer((_) async => null);
    when(() => storage.write(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
    manager = SessionManager(storage);
    notifications = 0;
    manager.addListener(() => notifications++);
  });

  test('restore lee el storage una sola vez', () async {
    when(() => storage.read()).thenAnswer((_) async => admin);

    final results = await Future.wait([manager.restore(), manager.restore()]);

    expect(results, [admin, admin]);
    expect(manager.isBusinessAdmin, isTrue);
    expect(manager.accessToken, 'tok');
    verify(() => storage.read()).called(1);
  });

  test('restore trata un storage corrupto como sin sesión', () async {
    when(() => storage.read()).thenThrow(Exception('corrupt'));
    expect(await manager.restore(), isNull);
    expect(manager.isBusinessAdmin, isFalse);
  });

  test('start guarda la sesión y avisa', () async {
    await manager.start(admin);

    verify(() => storage.write(admin)).called(1);
    expect(manager.current, admin);
    expect(await manager.restore(), admin);
    expect(notifications, 1);
  });

  test('end borra la sesión aunque falle el storage', () async {
    when(() => storage.clear()).thenThrow(Exception('io'));
    await manager.start(admin);

    await manager.end();

    expect(manager.current, isNull);
    expect(await manager.restore(), isNull);
    expect(manager.consumeExpired(), isFalse);
  });

  test('expire cierra la sesión y marca el aviso una sola vez', () async {
    await manager.start(admin);

    await manager.expire();

    expect(manager.current, isNull);
    expect(manager.consumeExpired(), isTrue);
    expect(manager.consumeExpired(), isFalse);
  });

  test('expire sin sesión no hace nada', () async {
    await manager.expire();
    expect(manager.consumeExpired(), isFalse);
    expect(notifications, 0);
  });
}
