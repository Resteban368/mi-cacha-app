import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/catalogs/domain/entities/catalog_court_surface.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/core/media/photo_picker.dart';
import 'package:mi_cancha/core/router/app_routes.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court.dart';
import 'package:mi_cancha/features/business_account/domain/entities/business_account.dart';
import 'package:mi_cancha/features/business_courts/presentation/bloc/court_form_bloc.dart';
import 'package:mi_cancha/features/business_courts/presentation/pages/court_form_page.dart';
import 'package:mi_cancha/features/business_courts/presentation/widgets/court_section_header.dart';
import 'package:mocktail/mocktail.dart';

import '../court_fixtures.dart';

class _MockBloc extends MockBloc<CourtFormEvent, CourtFormState>
    implements CourtFormBloc {}

class _FakePicker implements PhotoPicker {
  @override
  Future<PickedPhoto?> pick(PhotoSource source) async =>
      (bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0]), name: 'foto.jpg');
}

Subscription plan({
  int inUse = 0,
  String planName = 'Mi Cancha',
  int monthlyPrice = 117000,
  String? nextPlanName,
}) => Subscription(
  planName: planName,
  monthlyPrice: monthlyPrice,
  since: DateTime(2026),
  nextPayment: DateTime(2026, 2),
  courtLimit: 3,
  courtsInUse: inUse,
  nextPlanName: nextPlanName,
  benefits: const [],
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const CourtFormStarted());
  });

  late _MockBloc bloc;
  setUp(() => bloc = _MockBloc());

  final ready = CourtFormState(
    contextStatus: CourtFormContextStatus.ready,
    venueName: 'cancha dev',
    subscription: plan(),
    planKnown: true,
  );

  Future<void> pump(
    WidgetTester tester,
    CourtFormState state, {
    Size size = const Size(390, 844),
    Stream<CourtFormState>? stream,
    String? copyFrom,
    String? courtId,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    whenListen(
      bloc,
      stream ?? const Stream<CourtFormState>.empty(),
      initialState: state,
    );
    final router = GoRouter(
      initialLocation: AppRoutes.businessNewCourt,
      routes: [
        GoRoute(
          path: AppRoutes.businessCourts,
          builder: (_, _) => const Scaffold(body: Text('courts-list')),
        ),
        GoRoute(
          path: AppRoutes.businessNewCourt,
          builder: (_, _) => Scaffold(
            body: BlocProvider<CourtFormBloc>.value(
              value: bloc,
              child: CourtFormPage(
                photoPicker: _FakePicker(),
                copyFromCourtId: copyFrom,
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.businessProfile,
          builder: (_, _) => const Scaffold(body: Text('profile-page')),
        ),
        GoRoute(
          path: AppRoutes.businessSettings,
          builder: (_, _) => const Scaffold(body: Text('settings-page')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
  }

  FilledButton saveButton(WidgetTester tester) =>
      tester.widget(find.byKey(const Key('btn-save-court')));

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> pickPhoto(WidgetTester tester, CourtPhotoSlot slot) async {
    await tapVisible(tester, find.text(slot.hint));
    await tester.tap(find.text('Elegir de la galería'));
    await tester.pumpAndSettle();
  }

  Future<void> fillAll(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('court-name')), 'Cancha 1');
    await tapVisible(tester, find.text('Pádel'));
    for (final slot in createSlots) {
      await pickPhoto(tester, slot);
    }
    await tester.ensureVisible(find.byKey(const Key('court-base-price')));
    await tester.enterText(find.byKey(const Key('court-base-price')), '80000');
    await tester.pumpAndSettle();
  }

  testWidgets('muestra las secciones y lo que falta para guardar', (
    tester,
  ) async {
    await pump(tester, ready);

    expect(find.text('Nueva Cancha'), findsOneWidget);
    expect(find.text('cancha dev'), findsOneWidget);
    expect(find.text('Mi Cancha · 0 de 3 canchas usadas'), findsOneWidget);
    // Solo los deportes que acepta la API.
    for (final name in ['Fútbol', 'Pádel', 'Baloncesto', 'Voleibol']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Tenis'), findsNothing);
    expect(find.text('Rugby'), findsNothing);
    expect(find.text('Exigir anticipo para reservar'), findsNothing);

    expect(saveButton(tester).onPressed, isNull);
    expect(
      find.text('Falta: nombre, deporte, precio base, foto principal'),
      findsOneWidget,
    );
  });

  testWidgets('con todo completo envía la cancha y sus fotos', (tester) async {
    await pump(tester, ready);
    await fillAll(tester);

    expect(find.byKey(const Key('court-missing')), findsNothing);
    await tester.tap(find.byKey(const Key('btn-save-court')));
    await tester.pump();

    final event =
        verify(
              () => bloc.add(captureAny(that: isA<CourtFormSubmitted>())),
            ).captured.single
            as CourtFormSubmitted;
    expect(event.draft.name, 'Cancha 1');
    expect(event.draft.sport, Sport.padel);
    expect(event.draft.basePricePerHour, 80000);
    expect(event.draft.isActive, isTrue);
    expect(event.draft.isCovered, isFalse);
    expect(event.draft.slotDuration, 60);
    expect(event.draft.schedules, hasLength(7));
    expect(event.uploads.keys, createSlots);
  });

  testWidgets('al crear pide 2 fotos: principal y una segunda a elegir', (
    tester,
  ) async {
    await pump(tester, ready);

    expect(find.text('Segunda foto (opcional)'), findsOneWidget);
    expect(find.text(CourtPhotoSlot.lighting.hint), findsNothing);
    expect(find.text(CourtPhotoSlot.extra1.hint), findsNothing);

    await fillAll(tester);
    // La segunda foto pasa a iluminación sin volver a elegirla.
    await tapVisible(tester, find.byKey(const Key('second-photo-LIGHTING')));
    await tester.tap(find.byKey(const Key('btn-save-court')));
    await tester.pump();

    final event =
        verify(
              () => bloc.add(captureAny(that: isA<CourtFormSubmitted>())),
            ).captured.single
            as CourtFormSubmitted;
    expect(event.uploads.keys, {CourtPhotoSlot.main, CourtPhotoSlot.lighting});
  });

  testWidgets('la segunda foto es opcional: basta la principal', (
    tester,
  ) async {
    await pump(tester, ready);
    await tester.enterText(find.byKey(const Key('court-name')), 'Cancha 1');
    await tapVisible(tester, find.text('Pádel'));
    await pickPhoto(tester, CourtPhotoSlot.main);
    await tester.ensureVisible(find.byKey(const Key('court-base-price')));
    await tester.enterText(find.byKey(const Key('court-base-price')), '80000');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('court-missing')), findsNothing);
    expect(saveButton(tester).onPressed, isNotNull);
  });

  group('superficie y medidas', () {
    const surfaces = [
      CatalogCourtSurface(
        code: 'GRAMA_SINTETICA',
        name: 'Grama sintética',
        sports: {Sport.futbol, Sport.padel},
      ),
      CatalogCourtSurface(
        code: 'MADERA',
        name: 'Madera',
        sports: {Sport.baloncesto},
      ),
      CatalogCourtSurface(code: 'CEMENTO', name: 'Cemento'),
    ];
    final withSurfaces = ready.copyWith(courtSurfaces: surfaces);

    testWidgets('ofrece solo las superficies del deporte y las envía', (
      tester,
    ) async {
      await pump(tester, withSurfaces);
      expect(
        find.text('Elige el deporte para ver las superficies.'),
        findsOneWidget,
      );

      await fillAll(tester);
      expect(find.text('Grama sintética'), findsOneWidget);
      expect(find.text('Cemento'), findsOneWidget);
      expect(find.text('Madera'), findsNothing);

      await tapVisible(
        tester,
        find.byKey(const Key('court-surface-GRAMA_SINTETICA')),
      );
      await tester.enterText(find.byKey(const Key('court-length')), '20');
      await tester.enterText(find.byKey(const Key('court-width')), '10,5');
      await tester.enterText(find.byKey(const Key('court-players')), '2');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn-save-court')));
      await tester.pump();
      final event =
          verify(
                () => bloc.add(captureAny(that: isA<CourtFormSubmitted>())),
              ).captured.single
              as CourtFormSubmitted;
      expect(
        event.draft.specs,
        const CourtSpecs(
          surface: CourtSurfaceRef(
            code: 'GRAMA_SINTETICA',
            name: 'Grama sintética',
          ),
          lengthMeters: 20,
          widthMeters: 10.5,
          playersPerSide: 2,
        ),
      );
    });

    testWidgets('al cambiar a un deporte donde no aplica, la quita', (
      tester,
    ) async {
      await pump(tester, withSurfaces);
      await fillAll(tester);
      await tapVisible(
        tester,
        find.byKey(const Key('court-surface-GRAMA_SINTETICA')),
      );
      await tapVisible(tester, find.text('Baloncesto'));
      await tester.tap(find.byKey(const Key('btn-save-court')));
      await tester.pump();

      final event =
          verify(
                () => bloc.add(captureAny(that: isA<CourtFormSubmitted>())),
              ).captured.single
              as CourtFormSubmitted;
      expect(event.draft.specs.surface, isNull);
    });

    testWidgets('pide las dos medidas y un formato válido', (tester) async {
      await pump(tester, withSurfaces);
      await fillAll(tester);

      await tester.enterText(find.byKey(const Key('court-length')), '20');
      await tester.pumpAndSettle();
      expect(find.text('Falta: ancho de la cancha'), findsOneWidget);
      expect(saveButton(tester).onPressed, isNull);

      await tester.enterText(find.byKey(const Key('court-width')), '500');
      await tester.enterText(find.byKey(const Key('court-players')), '12');
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Falta: medidas entre 1 y 200 m, jugadores por equipo entre 1 y 11',
        ),
        findsOneWidget,
      );
    });
  });

  group('límite alcanzado', () {
    FilledButton limitButton(WidgetTester tester, String label) =>
        tester.widget(
          find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate((w) => w is FilledButton),
          ),
        );

    testWidgets('plan de pago: el botón pide más canchas por WhatsApp', (
      tester,
    ) async {
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      String? opened;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        opened = (call.arguments as Map)['url'] as String?;
        return true;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      await pump(
        tester,
        CourtFormState(
          contextStatus: CourtFormContextStatus.ready,
          venueName: 'El Campín',
          subscription: plan(inUse: 3),
          planKnown: true,
        ),
      );

      expect(
        find.text('Has usado 3 de 3 canchas disponibles en tu plan.'),
        findsOneWidget,
      );
      expect(limitButton(tester, 'Agregar más canchas').onPressed, isNotNull);
      await tapVisible(tester, find.text('Agregar más canchas'));

      expect(
        Uri.parse(opened!).queryParameters['text'],
        'Hola, soy el administrador de El Campín y quiero ampliar mi plan: '
        'hoy tengo 3 canchas contratadas y necesito más.',
      );
    });

    testWidgets('plan de pago con plan a medida: también agregar más canchas', (
      tester,
    ) async {
      await pump(
        tester,
        CourtFormState(
          contextStatus: CourtFormContextStatus.ready,
          subscription: plan(inUse: 3, nextPlanName: 'A medida'),
          planKnown: true,
        ),
      );
      expect(limitButton(tester, 'Agregar más canchas').onPressed, isNotNull);
      expect(find.textContaining('Cambiar al plan'), findsNothing);
    });

    testWidgets('en prueba: el botón cambia al plan Mi Cancha', (tester) async {
      await pump(
        tester,
        CourtFormState(
          contextStatus: CourtFormContextStatus.ready,
          subscription: plan(
            inUse: 3,
            planName: 'Prueba',
            monthlyPrice: 0,
            nextPlanName: 'Mi Cancha',
          ),
          planKnown: true,
        ),
      );
      expect(
        limitButton(tester, 'Cambiar al plan Mi Cancha').onPressed,
        isNotNull,
      );
      expect(find.text('Agregar más canchas'), findsNothing);
    });
  });

  testWidgets('con el plan lleno la cancha se crea inactiva', (tester) async {
    await pump(
      tester,
      CourtFormState(
        contextStatus: CourtFormContextStatus.ready,
        subscription: plan(inUse: 3),
        planKnown: true,
      ),
    );

    expect(find.text('Límite de canchas alcanzado'), findsOneWidget);
    expect(
      find.text('Tu plan no permite más canchas activas: se creará inactiva.'),
      findsOneWidget,
    );
    await fillAll(tester);
    await tester.tap(find.byKey(const Key('btn-save-court')));
    await tester.pump();

    final event =
        verify(
              () => bloc.add(captureAny(that: isA<CourtFormSubmitted>())),
            ).captured.single
            as CourtFormSubmitted;
    expect(event.draft.isActive, isFalse);
  });

  testWidgets('agrega una tarifa y avisa si se cruza con otra', (tester) async {
    await pump(tester, ready);

    Future<void> addRate(String name, String price) async {
      await tapVisible(tester, find.text('Agregar tarifa'));
      await tester.enterText(find.byKey(const Key('rate-name')), name);
      await tester.enterText(find.byKey(const Key('rate-price')), price);
      await tester.tap(find.text('L-V'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('rate-save')));
      await tester.pumpAndSettle();
    }

    await addRate('Nocturna', '90000');
    expect(find.text('Nocturna'), findsOneWidget);
    expect(find.text(r'$90.000/h'), findsOneWidget);
    expect(find.text('Lun a Vie · 18:00 – 22:00'), findsOneWidget);
    expect(find.text('1 tarifa'), findsOneWidget);

    // Mismos días y horas: se cruza.
    await addRate('Otra', '50000');
    expect(
      find.text(
        'Se cruza con la tarifa "Nocturna". Cambia los días o las horas.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('sin negocio registrado lleva a Mi negocio', (tester) async {
    await pump(
      tester,
      const CourtFormState(
        contextStatus: CourtFormContextStatus.ready,
        hasBusiness: false,
      ),
    );
    expect(find.text('Primero registra tu negocio'), findsOneWidget);
    await tester.tap(find.text('Ir a Mi negocio'));
    await tester.pumpAndSettle();
    expect(find.text('profile-page'), findsOneWidget);
  });

  testWidgets('al crear avisa y vuelve a la lista', (tester) async {
    await pump(
      tester,
      ready,
      stream: Stream.value(
        ready.copyWith(
          submitStatus: CourtFormSubmitStatus.success,
          saved: () => courtWith({...createSlots}),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.text(
        'Cancha "Cancha Central Pádel 1" creada y lista para reservas.',
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(find.text('courts-list'), findsOneWidget);
  });

  testWidgets('foto fallida: avisa y ofrece reintentar', (tester) async {
    final failed = ready.copyWith(
      submitStatus: CourtFormSubmitStatus.photosFailed,
      pendingCourt: () => courtWith({CourtPhotoSlot.main}),
      failedPhotos: {CourtPhotoSlot.surface},
    );
    await pump(tester, ready, stream: Stream.value(failed));
    await tester.pump();

    expect(
      find.text(
        'La cancha se creó, pero 1 foto no se actualizó. Toca '
        '"Reintentar fotos".',
      ),
      findsOneWidget,
    );
    expect(find.text('Reintentar fotos'), findsOneWidget);
  });

  group('web', () {
    testWidgets('dos columnas: datos a la izquierda, horario a la derecha', (
      tester,
    ) async {
      await pump(tester, ready, size: const Size(1280, 900));

      final datos = tester.getTopLeft(find.text('Datos Básicos'));
      final horario = tester.getTopLeft(find.text('Horario Semanal'));
      expect(horario.dx, greaterThan(datos.dx + 400));
      expect(horario.dy, moreOrLessEquals(datos.dy, epsilon: 4));
      expect(
        tester.getSize(find.byKey(const Key('btn-save-court'))).width,
        lessThanOrEqualTo(320),
      );
    });

    testWidgets('en el celular sigue en una columna', (tester) async {
      await pump(tester, ready);
      final datos = tester.getTopLeft(find.byType(CourtSectionHeader).first);
      final titulo = tester.getTopLeft(find.text('Nueva Cancha'));
      expect(datos.dx, moreOrLessEquals(titulo.dx, epsilon: 1));
    });

    for (final size in const [
      Size(320, 568),
      Size(900, 700),
      Size(1024, 768),
      Size(1440, 900),
    ]) {
      testWidgets('sin overflow en ${size.width}x${size.height}', (
        tester,
      ) async {
        await pump(tester, ready, size: size);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -3000),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('copiar de otra cancha', () {
    final withCourts = ready.copyWith(existingCourts: [padelCourt]);

    testWidgets('sin canchas creadas no se ofrece', (tester) async {
      await pump(tester, ready);
      expect(find.byKey(const Key('copy-from-court')), findsNothing);
    });

    testWidgets('copia horario y precio, sin las tarifas desmarcadas', (
      tester,
    ) async {
      await pump(tester, withCourts, size: const Size(390, 1800));
      await tester.tap(find.byKey(const Key('copy-from-court')));
      await tester.pumpAndSettle();

      expect(find.text('Copiar de otra cancha'), findsOneWidget);
      await tester.tap(find.text('Tarifas por franja'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('copy-court-confirm')));
      await tester.pumpAndSettle();

      expect(
        find.text('Copiado de "Cancha Central Pádel 1": horario, precio.'),
        findsOneWidget,
      );
      // Domingo cerrado y viernes hasta las 02:00, como la cancha copiada.
      expect(find.text('Cerrado'), findsOneWidget);
      expect(find.text('02:00'), findsNWidgets(2));
      expect(find.text('89.900'), findsOneWidget);
      expect(find.text('Aún no has agregado tarifas'), findsOneWidget);
    });

    testWidgets('"Usar como base" abre la copia con esa cancha', (
      tester,
    ) async {
      await pump(tester, withCourts, copyFrom: 'c-padel');
      await tester.pumpAndSettle();
      expect(find.text('Copiar de otra cancha'), findsOneWidget);

      await tester.tap(find.byKey(const Key('copy-court-confirm')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Copiado de "Cancha Central Pádel 1": horario, precio, tarifas.',
        ),
        findsOneWidget,
      );
      expect(find.text('2 tarifas'), findsOneWidget);
    });
  });

  group('editar', () {
    final editing = ready.copyWith(
      existingCourts: [padelCourt],
      editing: () => padelCourt,
    );

    testWidgets('precarga la cancha y guarda los cambios', (tester) async {
      await pump(
        tester,
        editing,
        courtId: 'c-padel',
        size: const Size(390, 1800),
      );

      expect(find.text('Editar cancha'), findsOneWidget);
      expect(find.text('Cancha Central Pádel 1'), findsOneWidget);
      expect(find.text('89.900'), findsOneWidget);
      expect(find.text('2 tarifas'), findsOneWidget);
      // Con la foto principal ya subida no falta ninguna.
      expect(find.byKey(const Key('court-missing')), findsNothing);

      await tester.enterText(find.byKey(const Key('court-name')), 'Pádel 1');
      await pickPhoto(tester, CourtPhotoSlot.surface);
      await pickPhoto(tester, CourtPhotoSlot.lighting);
      expect(find.text('Guardar cambios'), findsOneWidget);
      await tester.tap(find.byKey(const Key('btn-save-court')));
      await tester.pump();

      final event =
          verify(
                () => bloc.add(captureAny(that: isA<CourtFormSubmitted>())),
              ).captured.single
              as CourtFormSubmitted;
      expect(event.draft.name, 'Pádel 1');
      expect(event.draft.sport, Sport.padel);
      expect(event.draft.isCovered, isTrue);
      expect(event.draft.slotDuration, 90);
      expect(event.draft.rates, padelCourt.rates);
      expect(event.uploads.keys, {
        CourtPhotoSlot.surface,
        CourtPhotoSlot.lighting,
      });
      expect(event.removals, isEmpty);
    });

    testWidgets('quitar fotos: la opcional se borra, la reemplazada no', (
      tester,
    ) async {
      final complete = Court(
        id: 'c-full',
        name: 'Completa',
        sport: Sport.futbol,
        isActive: true,
        isComplete: true,
        isBookable: true,
        basePricePerHour: 50000,
        schedules: padelDraft.schedules,
        photos: {
          for (final slot in [...createSlots, CourtPhotoSlot.extra1])
            slot: 'https://api.test/${slot.apiCode}.jpg',
        },
      );
      await pump(
        tester,
        ready.copyWith(existingCourts: [complete], editing: () => complete),
        courtId: 'c-full',
        size: const Size(390, 1800),
      );

      await tapVisible(tester, find.byTooltip('Quitar Foto 4 · Opcional'));
      await tapVisible(tester, find.byTooltip('Quitar Foto 1 (Principal)'));
      expect(find.text('Falta: foto principal'), findsOneWidget);
      await pickPhoto(tester, CourtPhotoSlot.main);

      await tester.tap(find.byKey(const Key('btn-save-court')));
      await tester.pump();
      final event =
          verify(
                () => bloc.add(captureAny(that: isA<CourtFormSubmitted>())),
              ).captured.single
              as CourtFormSubmitted;
      expect(event.uploads.keys, [CourtPhotoSlot.main]);
      expect(event.removals, {CourtPhotoSlot.extra1});
    });

    testWidgets('cancha que no existe vuelve a la lista', (tester) async {
      await pump(
        tester,
        const CourtFormState(contextStatus: CourtFormContextStatus.notFound),
        courtId: 'x',
      );
      expect(find.text('No encontramos esta cancha'), findsOneWidget);
      await tester.tap(find.text('Ver mis canchas'));
      await tester.pumpAndSettle();
      expect(find.text('courts-list'), findsOneWidget);
    });

    testWidgets('al guardar avisa y vuelve a la lista', (tester) async {
      await pump(
        tester,
        editing,
        courtId: 'c-padel',
        stream: Stream.value(
          editing.copyWith(
            submitStatus: CourtFormSubmitStatus.success,
            saved: () => padelCourt,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(
          'Cancha "Cancha Central Pádel 1" guardada y lista para reservas.',
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(find.text('courts-list'), findsOneWidget);
    });
  });
}
