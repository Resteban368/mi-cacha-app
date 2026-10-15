import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/features/onboarding/presentation/widgets/onboarding_step_availability.dart';
import 'package:mi_cancha/features/onboarding/presentation/widgets/onboarding_step_booking.dart';
import 'package:mi_cancha/features/onboarding/presentation/widgets/onboarding_step_discover.dart';

/// Regresión: ningún paso debe desbordar en pantallas comunes, incluso
/// cuando las ilustraciones SVG ya cargaron y ocupan su alto real.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final steps = <String, Widget>{
    'paso 1': OnboardingStepDiscover(onNext: () {}, onSkip: () {}),
    'paso 2': OnboardingStepAvailability(
      onNext: () {},
      onBack: () {},
      onSkip: () {},
    ),
    'paso 3': OnboardingStepBooking(onStart: () {}, onLogin: () {}),
  };

  const sizes = [
    Size(320, 568), // iPhone SE (1.ª gen.)
    Size(360, 640),
    Size(393, 736), // tamaño del reporte de overflow
    Size(412, 915),
    // Web / escritorio
    Size(900, 560),
    Size(1024, 600),
    Size(1200, 500), // ventana baja: vuelve a la columna móvil
    Size(1440, 900),
    Size(1920, 1080),
  ];

  for (final MapEntry(key: name, value: step) in steps.entries) {
    for (final size in sizes) {
      testWidgets('$name sin overflow en ${size.width}x${size.height}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(MaterialApp(home: Scaffold(body: step)));
        // Dejar que los SVG se carguen del bundle y se relayouteen.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('en web la ilustración va a la izquierda de los textos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: steps['paso 1']!)),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final media = tester.getRect(find.text('14 canchas cerca de ti'));
    final title = tester.getRect(find.text('Todas las canchas de tu ciudad'));
    final next = tester.getRect(find.text('Siguiente'));
    expect(title.left, greaterThan(media.right));
    expect(next.left, greaterThan(media.right));

    // Textos alineados a la izquierda y la ilustración agrandada.
    final pill = tester.getRect(find.text('PASO 1 DE 3 • DESCUBRE'));
    final description = tester.getRect(
      find.textContaining('Fútbol, pádel, baloncesto'),
    );
    expect(pill.left, moreOrLessEquals(description.left, epsilon: 40));
    expect(title.left, moreOrLessEquals(description.left, epsilon: 1));
    expect(
      tester.getSize(find.byType(FittedBox).first).width,
      greaterThan(500),
    );
  });

  testWidgets('en móvil los textos siguen centrados', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: steps['paso 1']!)),
    );
    await tester.pump();

    final title = tester.getRect(find.text('Todas las canchas de tu ciudad'));
    expect(title.center.dx, moreOrLessEquals(206, epsilon: 1));
  });
}
