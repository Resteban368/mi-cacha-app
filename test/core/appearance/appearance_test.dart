import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/app/app.dart';
import 'package:mi_cancha/core/appearance/appearance_cubit.dart';
import 'package:mi_cancha/core/appearance/appearance_mode.dart';
import 'package:mi_cancha/core/appearance/appearance_storage.dart';
import 'package:mi_cancha/core/theme/app_colors.dart';
import 'package:mi_cancha/core/theme/app_palette.dart';
import 'package:mi_cancha/core/theme/app_theme.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements AppearanceStorage {}

void main() {
  setUpAll(() => registerFallbackValue(AppearanceMode.system));

  late _MockStorage storage;
  setUp(() {
    storage = _MockStorage();
    when(() => storage.write(any())).thenAnswer((_) async {});
  });
  // Ninguna prueba deja la app en oscuro.
  tearDown(() => AppColors.use(Brightness.light));

  group('AppearanceCubit', () {
    blocTest<AppearanceCubit, AppearanceMode>(
      'arranca en "Sistema" y carga el modo guardado',
      setUp: () => when(
        () => storage.read(),
      ).thenAnswer((_) async => AppearanceMode.dark),
      build: () => AppearanceCubit(storage),
      act: (cubit) => cubit.load(),
      expect: () => [AppearanceMode.dark],
    );

    blocTest<AppearanceCubit, AppearanceMode>(
      'elegir un modo lo aplica y lo guarda',
      build: () => AppearanceCubit(storage),
      act: (cubit) => cubit.select(AppearanceMode.light),
      expect: () => [AppearanceMode.light],
      verify: (_) =>
          verify(() => storage.write(AppearanceMode.light)).called(1),
    );

    blocTest<AppearanceCubit, AppearanceMode>(
      'el mismo modo no se vuelve a guardar',
      build: () => AppearanceCubit(storage),
      act: (cubit) => cubit.select(AppearanceMode.system),
      expect: () => const <AppearanceMode>[],
      verify: (_) => verifyNever(() => storage.write(any())),
    );

    blocTest<AppearanceCubit, AppearanceMode>(
      'si no se puede guardar, el cambio vale para la sesión',
      setUp: () => when(() => storage.write(any())).thenThrow(Exception()),
      build: () => AppearanceCubit(storage),
      act: (cubit) => cubit.select(AppearanceMode.dark),
      expect: () => [AppearanceMode.dark],
    );
  });

  test('el código guardado se lee; uno desconocido sigue al sistema', () {
    expect(AppearanceMode.fromStorage('dark'), AppearanceMode.dark);
    expect(AppearanceMode.fromStorage('light'), AppearanceMode.light);
    expect(AppearanceMode.fromStorage(null), AppearanceMode.system);
    expect(AppearanceMode.fromStorage('otro'), AppearanceMode.system);
  });

  group('paleta', () {
    test('claro y oscuro cambian los colores del tema', () {
      expect(applyAppearance(AppearanceMode.dark), isTrue);
      expect(AppColors.isDark, isTrue);
      expect(AppColors.surface, AppPalette.dark.surface);
      expect(AppTheme.current.brightness, Brightness.dark);

      // El mismo modo no cuenta como cambio.
      expect(applyAppearance(AppearanceMode.dark), isFalse);

      expect(applyAppearance(AppearanceMode.light), isTrue);
      expect(AppColors.surface, AppPalette.light.surface);
      expect(AppTheme.current.brightness, Brightness.light);
    });

    testWidgets('"Sistema" sigue el modo del dispositivo', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      applyAppearance(AppearanceMode.system);
      expect(AppColors.isDark, isTrue);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      applyAppearance(AppearanceMode.system);
      expect(AppColors.isDark, isFalse);
    });

    test('colores de la marca', () {
      expect(AppPalette.light.brandTealGlow, const Color(0xFF00C853));
      expect(AppPalette.light.onSurface, const Color(0xFF0B1F28));
      expect(AppPalette.light.surface, const Color(0xFFF8FAFC));
      expect(AppPalette.dark.surface, const Color(0xFF0B1F28));
    });
  });
}
