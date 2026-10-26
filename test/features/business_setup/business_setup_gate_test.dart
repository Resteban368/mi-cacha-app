import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/router/app_router.dart';
import 'package:mi_cancha/core/router/app_routes.dart';
import 'package:mi_cancha/core/session/session.dart';
import 'package:mi_cancha/core/session/session_manager.dart';
import 'package:mi_cancha/core/session/session_storage.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/business_setup/domain/entities/setup_progress.dart';
import 'package:mi_cancha/features/business_setup/domain/usecases/get_setup_progress.dart';
import 'package:mi_cancha/features/business_setup/presentation/business_setup_gate.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements SessionStorage {}

class _MockGetSetupProgress extends Mock implements GetSetupProgress {}

void main() {
  const admin = Session(
    accessToken: 'tok',
    role: 'ADMIN_NEGOCIO',
    displayName: 'Andrés',
  );

  late SessionManager session;
  late _MockGetSetupProgress getProgress;
  late BusinessSetupGate gate;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(admin);
  });

  setUp(() async {
    final storage = _MockStorage();
    when(() => storage.read()).thenAnswer((_) async => admin);
    when(() => storage.write(any())).thenAnswer((_) async {});
    session = SessionManager(storage);
    await session.restore();
    getProgress = _MockGetSetupProgress();
    gate = BusinessSetupGate(getProgress, session);
  });

  void progressIs(SetupStep step) => when(
    () => getProgress(any()),
  ).thenAnswer((_) async => SetupProgress(step));

  Future<String?> guard(String path) =>
      businessGuard(session, path, setup: gate);

  group('sin el negocio completo', () {
    setUp(() => progressIs(SetupStep.business));

    test('el login y las demás secciones llevan a Mi negocio', () async {
      expect(await guard(AppRoutes.businessLogin), AppRoutes.businessProfile);
      expect(
        await guard(AppRoutes.businessReservations),
        AppRoutes.businessProfile,
      );
      expect(await guard(AppRoutes.businessCourts), AppRoutes.businessProfile);
    });

    test('Mi negocio y Mi cuenta quedan abiertas', () async {
      expect(await guard(AppRoutes.businessProfile), isNull);
      expect(await guard(AppRoutes.businessSettings), isNull);
    });
  });

  test('sin cancha lista solo abre Canchas (y su formulario)', () async {
    progressIs(SetupStep.court);
    expect(await guard(AppRoutes.businessLogin), AppRoutes.businessCourts);
    expect(await guard(AppRoutes.businessPayments), AppRoutes.businessCourts);
    expect(await guard(AppRoutes.businessNewCourt), isNull);
    expect(await guard('/negocio/canchas/editar/k1'), isNull);
    expect(await guard(AppRoutes.businessProfile), isNull);
  });

  test('completo entra a Reservas', () async {
    progressIs(SetupStep.done);
    expect(
      await guard(AppRoutes.businessLogin),
      AppRoutes.businessReservations,
    );
    expect(await guard(AppRoutes.businessPayments), isNull);
  });

  test('si la consulta falla no bloquea y reintenta después', () async {
    when(() => getProgress(any())).thenThrow(Exception('sin red'));
    expect(await guard(AppRoutes.businessPayments), isNull);
    progressIs(SetupStep.business);
    expect(await guard(AppRoutes.businessPayments), AppRoutes.businessProfile);
  });

  test('consulta la API una vez por sesión', () async {
    progressIs(SetupStep.done);
    await guard(AppRoutes.businessPayments);
    await guard(AppRoutes.businessClients);
    verify(() => getProgress(any())).called(1);

    await session.start(
      const Session(
        accessToken: 'otro',
        role: 'ADMIN_NEGOCIO',
        displayName: 'Otro',
      ),
    );
    await guard(AppRoutes.businessPayments);
    verify(() => getProgress(any())).called(1);
  });

  test('al avanzar de paso lleva una vez a la pantalla del paso', () async {
    progressIs(SetupStep.business);
    expect(await guard(AppRoutes.businessProfile), isNull);

    progressIs(SetupStep.court);
    await gate.refresh();
    expect(await guard(AppRoutes.businessProfile), AppRoutes.businessCourts);
    expect(await guard(AppRoutes.businessProfile), isNull);

    progressIs(SetupStep.done);
    await gate.refresh();
    expect(
      await guard(AppRoutes.businessCourts),
      AppRoutes.businessReservations,
    );
  });
}
