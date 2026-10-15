import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/splash/domain/entities/start_destination.dart';
import 'package:mi_cancha/features/splash/domain/usecases/get_app_version.dart';
import 'package:mi_cancha/features/splash/domain/usecases/resolve_start_destination.dart';
import 'package:mi_cancha/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockResolve extends Mock implements ResolveStartDestination {}

class _MockGetVersion extends Mock implements GetAppVersion {}

void main() {
  late _MockResolve resolve;
  late _MockGetVersion getVersion;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    resolve = _MockResolve();
    getVersion = _MockGetVersion();
    when(() => getVersion(any())).thenAnswer((_) async => '1.0.0');
  });

  SplashBloc build() => SplashBloc(
    resolveStartDestination: resolve,
    getAppVersion: getVersion,
    minDisplayDuration: Duration.zero,
  );

  test('estado inicial sin versión ni destino', () {
    expect(build().state, const SplashState());
  });

  blocTest<SplashBloc, SplashState>(
    'emite la versión y luego destino login sin sesión',
    setUp: () => when(
      () => resolve(any()),
    ).thenAnswer((_) async => StartDestination.login),
    build: build,
    act: (bloc) => bloc.add(const SplashStarted()),
    expect: () => const [
      SplashState(version: '1.0.0'),
      SplashState(version: '1.0.0', destination: StartDestination.login),
    ],
  );

  blocTest<SplashBloc, SplashState>(
    'emite destino home con sesión activa',
    setUp: () => when(
      () => resolve(any()),
    ).thenAnswer((_) async => StartDestination.home),
    build: build,
    act: (bloc) => bloc.add(const SplashStarted()),
    expect: () => const [
      SplashState(version: '1.0.0'),
      SplashState(version: '1.0.0', destination: StartDestination.home),
    ],
  );

  test('respeta la duración mínima en pantalla', () async {
    when(() => resolve(any())).thenAnswer((_) async => StartDestination.login);
    final bloc = SplashBloc(
      resolveStartDestination: resolve,
      getAppVersion: getVersion,
      minDisplayDuration: const Duration(milliseconds: 300),
    );
    final watch = Stopwatch()..start();
    bloc.add(const SplashStarted());
    await bloc.stream.firstWhere((s) => s.destination != null);
    expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(300));
    await bloc.close();
  });
}
