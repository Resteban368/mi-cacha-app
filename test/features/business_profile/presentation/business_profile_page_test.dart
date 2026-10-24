import 'package:bloc_test/bloc_test.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/location/device_location.dart';
import 'package:mi_cancha/core/location/geo_point.dart';
import 'package:mi_cancha/core/media/photo_picker.dart';
import 'package:mi_cancha/core/router/app_routes.dart';
import 'package:mi_cancha/features/business_profile/domain/entities/business.dart';
import 'package:mi_cancha/core/media/image_upload.dart';
import 'package:mi_cancha/features/business_profile/presentation/bloc/business_profile_bloc.dart';
import 'package:mi_cancha/features/business_profile/presentation/pages/business_profile_page.dart';
import 'package:mi_cancha/features/business_profile/presentation/widgets/business_media_fields.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/blank_tile_provider.dart';
import '../business_fixtures.dart';

class _MockBloc extends MockBloc<BusinessProfileEvent, BusinessProfileState>
    implements BusinessProfileBloc {}

class _FakePicker implements PhotoPicker {
  final sources = <PhotoSource>[];
  Object? error;

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    sources.add(source);
    if (error case final error?) throw error;
    return (bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0]), name: 'a.jpg');
  }
}

class _FakeLocation implements DeviceLocation {
  GeoPoint point = const GeoPoint(2.4448, -76.6147);
  DeviceLocationError? error;
  var settingsOpened = false;

  @override
  Future<GeoPoint> current() async {
    if (error case final error?) throw DeviceLocationException(error);
    return point;
  }

  @override
  Future<void> openSettings() async => settingsOpened = true;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const BusinessProfileRequested());
  });

  late _MockBloc bloc;
  late GoRouter router;
  late _FakePicker picker;
  late _FakeLocation location;
  setUp(() {
    bloc = _MockBloc();
    picker = _FakePicker();
    location = _FakeLocation();
  });

  const empty = BusinessProfileState(
    status: BusinessProfileStatus.ready,
    amenityOptions: amenityCatalog,
    amenityStatus: AmenityCatalogStatus.ready,
  );

  Future<void> pump(
    WidgetTester tester,
    BusinessProfileState state, {
    Size size = const Size(390, 1600),
    Stream<BusinessProfileState>? stream,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    whenListen(
      bloc,
      stream ?? const Stream<BusinessProfileState>.empty(),
      initialState: state,
    );
    router = GoRouter(
      initialLocation: AppRoutes.businessProfile,
      routes: [
        GoRoute(
          path: AppRoutes.businessProfile,
          builder: (_, _) => Scaffold(
            body: BlocProvider<BusinessProfileBloc>.value(
              value: bloc,
              child: BusinessProfilePage(
                photoPicker: picker,
                deviceLocation: location,
                mapTileProvider: BlankTileProvider(),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.businessCourts,
          builder: (_, _) => const Scaffold(body: Text('courts-page')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
  }

  FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.ancestor(
      of: find.text('Guardar negocio y continuar'),
      matching: find.byType(FilledButton),
    ),
  );

  Future<void> fillRequired(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'El Campín');
    await tester.enterText(fields.at(1), 'Carrera 11 # 18-45');
    await tester.enterText(fields.at(2), 'Centro');
    await tester.pump();
  }

  testWidgets('estado vacío: textos del diseño y botón deshabilitado', (
    tester,
  ) async {
    await pump(tester, empty);

    expect(find.text('Registra tu sede deportiva'), findsOneWidget);
    expect(find.text('Subir fotos de la sede'), findsOneWidget);
    expect(find.text('Sin ubicación fijada'), findsOneWidget);
    expect(find.text('Fijar en el mapa'), findsOneWidget);
    expect(find.text('Sin fijar'), findsOneWidget);
    // Servicios del catálogo de la API, con sus nombres del panel.
    for (final amenity in amenityCatalog) {
      expect(find.text(amenity.name), findsOneWidget);
    }
    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets(
    'se habilita con nombre, dirección y barrio y envía el borrador',
    (tester) async {
      await pump(tester, empty);
      await fillRequired(tester);
      expect(saveButton(tester).onPressed, isNotNull);

      await tester.ensureVisible(find.text('Parqueadero'));
      await tester.tap(find.text('Parqueadero'));
      await tester.pump();
      await tester.tap(find.text('Guardar negocio y continuar'));
      await tester.pump();

      verify(
        () => bloc.add(
          any(
            that: isA<BusinessProfileSaved>()
                .having((e) => e.draft.name, 'nombre', 'El Campín')
                .having((e) => e.draft.neighborhood, 'barrio', 'Centro')
                .having((e) => e.draft.amenities, 'servicios', {'PARQUEADERO'}),
          ),
        ),
      ).called(1);
    },
  );

  testWidgets('al crear continúa a Canchas', (tester) async {
    await pump(
      tester,
      empty,
      stream: Stream.value(
        const BusinessProfileState(
          status: BusinessProfileStatus.ready,
          amenityOptions: amenityCatalog,
          amenityStatus: AmenityCatalogStatus.ready,
          business: business,
          saveStatus: BusinessSaveStatus.created,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('courts-page'), findsOneWidget);
  });

  testWidgets('con negocio existente precarga los datos para editar', (
    tester,
  ) async {
    await pump(
      tester,
      const BusinessProfileState(
        status: BusinessProfileStatus.ready,
        amenityOptions: amenityCatalog,
        amenityStatus: AmenityCatalogStatus.ready,
        business: business,
      ),
    );

    expect(find.text('Tu sede deportiva'), findsOneWidget);
    expect(find.text('Complejo Deportivo El Campín'), findsOneWidget);
    expect(find.text('Guardar cambios'), findsOneWidget);
  });

  testWidgets('en el celular elige el origen y envía la foto al bloc', (
    tester,
  ) async {
    await pump(tester, empty);
    await tester.tap(find.text('Subir fotos de la sede'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomar una foto'));
    await tester.pumpAndSettle();

    expect(picker.sources, [PhotoSource.camera]);
    verify(
      () => bloc.add(
        any(
          that: isA<BusinessPhotoPicked>().having(
            (e) => e.image.fileName,
            'archivo',
            'a.jpg',
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('si el selector falla avisa en vez de quedarse quieto', (
    tester,
  ) async {
    picker.error = MissingPluginException('sin plugin');
    await pump(tester, empty);
    await tester.tap(find.text('Subir fotos de la sede'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir de la galería'));
    await tester.pumpAndSettle();

    expect(
      find.text('No pudimos abrir tus fotos. Revisa los permisos.'),
      findsOneWidget,
    );
    verifyNever(() => bloc.add(any(that: isA<BusinessPhotoPicked>())));
  });

  group('galería', () {
    BusinessProfileState withPhotos(int count) => BusinessProfileState(
      status: BusinessProfileStatus.ready,
      amenityOptions: amenityCatalog,
      amenityStatus: AmenityCatalogStatus.ready,
      business: Business(
        id: 'b1',
        name: 'El Campín',
        address: 'Carrera 11',
        neighborhood: 'Centro',
        imageUrl: 'https://api.test/p1.jpg',
        photos: [
          for (var i = 1; i <= count; i++)
            BusinessPhoto(id: 'p$i', url: 'https://api.test/p$i.jpg'),
        ],
      ),
    );

    String mainUrl(WidgetTester tester) {
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byKey(const Key('gallery-main')),
          matching: find.byType(Image),
        ),
      );
      return (image.image as NetworkImage).url;
    }

    VoidCallback? onPressed(WidgetTester tester, String key) =>
        tester.widget<ButtonStyleButton>(find.byKey(Key(key))).onPressed;

    testWidgets('muestra la portada, miniaturas y el contador', (tester) async {
      await pump(tester, withPhotos(2));

      expect(mainUrl(tester), 'https://api.test/p1.jpg');
      expect(find.text('Portada'), findsOneWidget);
      expect(find.byKey(const Key('gallery-thumb-p1')), findsOneWidget);
      expect(find.byKey(const Key('gallery-thumb-p2')), findsOneWidget);
      expect(
        find.text('2 de 5 fotos · la primera es la portada'),
        findsOneWidget,
      );
      // La portada no se puede volver a hacer portada ni mover a la izquierda.
      expect(onPressed(tester, 'gallery-make-cover'), isNull);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('gallery-move-left')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('elegir otra y hacerla portada envía el nuevo orden', (
      tester,
    ) async {
      await pump(tester, withPhotos(3));

      await tester.tap(find.byKey(const Key('gallery-thumb-p3')));
      await tester.pump();
      expect(mainUrl(tester), 'https://api.test/p3.jpg');
      expect(find.text('Portada'), findsNothing);

      await tester.tap(find.byKey(const Key('gallery-make-cover')));
      verify(
        () => bloc.add(const BusinessPhotosReordered(['p3', 'p1', 'p2'])),
      ).called(1);

      await tester.tap(find.byKey(const Key('gallery-move-left')));
      verify(
        () => bloc.add(const BusinessPhotosReordered(['p1', 'p3', 'p2'])),
      ).called(1);
    });

    testWidgets('mover a la derecha', (tester) async {
      await pump(tester, withPhotos(2));
      await tester.tap(find.byKey(const Key('gallery-move-right')));
      verify(
        () => bloc.add(const BusinessPhotosReordered(['p2', 'p1'])),
      ).called(1);
    });

    testWidgets('eliminar pide confirmación', (tester) async {
      await pump(tester, withPhotos(2));
      await tester.tap(find.byKey(const Key('gallery-thumb-p2')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('gallery-delete')));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar esta foto?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('photo-remove-cancel')));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any(that: isA<BusinessPhotoRemoved>())));

      await tester.tap(find.byKey(const Key('gallery-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('photo-remove-confirm')));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const BusinessPhotoRemoved('p2'))).called(1);
    });

    testWidgets('con 5 fotos no deja agregar otra', (tester) async {
      await pump(tester, withPhotos(5));

      expect(
        find.text('5 de 5 fotos · la primera es la portada'),
        findsOneWidget,
      );
      expect(
        tester.widget<InkWell>(find.byKey(const Key('gallery-add'))).onTap,
        isNull,
      );
      expect(find.byTooltip('Máximo 5 fotos'), findsOneWidget);
    });

    testWidgets('con menos de 5 agrega desde la miniatura "+"', (tester) async {
      await pump(tester, withPhotos(2));
      await tester.tap(find.byKey(const Key('gallery-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elegir de la galería'));
      await tester.pumpAndSettle();

      verify(() => bloc.add(any(that: isA<BusinessPhotoPicked>()))).called(1);
    });

    testWidgets('sin overflow en 320 de ancho con 5 fotos', (tester) async {
      await pump(tester, withPhotos(5), size: const Size(320, 1800));
      await tester.tap(find.byKey(const Key('gallery-thumb-p3')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('al llegar al límite avisa', (tester) async {
      final full = withPhotos(5);
      await pump(
        tester,
        full,
        stream: Stream.value(
          full.copyWith(photoStatus: BusinessPhotoStatus.limitReached),
        ),
      );
      await tester.pump();
      expect(
        find.text('Ya tienes 5 fotos. Elimina una para agregar otra.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('foto pendiente al crear: avisa que se subirá al guardar', (
    tester,
  ) async {
    await pump(
      tester,
      BusinessProfileState(
        status: BusinessProfileStatus.ready,
        amenityOptions: amenityCatalog,
        amenityStatus: AmenityCatalogStatus.ready,
        pendingPhoto: ImageUpload(
          bytes: Uint8List.fromList([0xff, 0xd8, 0xff]),
          fileName: 'a.jpg',
        ),
      ),
    );
    expect(find.text('Se subirá al guardar'), findsOneWidget);
  });

  testWidgets('foto muy pesada muestra el aviso de 4 MB', (tester) async {
    await pump(
      tester,
      empty,
      stream: Stream.value(
        empty.copyWith(photoStatus: BusinessPhotoStatus.tooLarge),
      ),
    );
    await tester.pump();
    expect(
      find.text('La foto supera los 4 MB. Elige una más liviana.'),
      findsOneWidget,
    );
  });

  testWidgets('web: dos columnas con portada y mapa a la derecha', (
    tester,
  ) async {
    await pump(tester, empty, size: const Size(1280, 1000));

    final nombre = tester.getTopLeft(find.byType(TextFormField).first);
    final portada = tester.getTopLeft(find.byType(BusinessPhotoGallery));
    expect(portada.dx, greaterThan(nombre.dx + 300));
    // El botón no se estira a todo el ancho.
    expect(
      tester.getSize(find.byType(FilledButton).last).width,
      lessThanOrEqualTo(360),
    );
  });

  for (final size in const [
    Size(320, 568),
    Size(412, 915),
    Size(900, 700),
    Size(1440, 900),
  ]) {
    testWidgets('sin overflow en ${size.width}x${size.height}', (tester) async {
      await pump(tester, empty, size: size);
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('marca los servicios que ya tiene el negocio', (tester) async {
    await pump(
      tester,
      const BusinessProfileState(
        status: BusinessProfileStatus.ready,
        business: business,
        amenityOptions: amenityCatalog,
        amenityStatus: AmenityCatalogStatus.ready,
      ),
    );

    Matcher chip({required bool selected}) =>
        containsSemantics(isButton: true, isSelected: selected);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Parqueadero')),
      chip(selected: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('WiFi Gratis')),
      chip(selected: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Sauna')),
      chip(selected: false),
    );
  });

  testWidgets('si el catálogo falla, avisa y permite reintentar', (
    tester,
  ) async {
    await pump(
      tester,
      empty.copyWith(amenityStatus: AmenityCatalogStatus.failure),
    );

    expect(find.text('No pudimos cargar los servicios.'), findsOneWidget);
    // El resto del formulario sigue disponible.
    expect(find.text('Registra tu sede deportiva'), findsOneWidget);

    await tester.ensureVisible(find.text('Reintentar'));
    await tester.tap(find.text('Reintentar'));
    verify(() => bloc.add(const BusinessAmenitiesRequested())).called(1);
  });

  testWidgets('catálogo vacío', (tester) async {
    await pump(tester, empty.copyWith(amenityOptions: const []));
    expect(
      find.text('Aún no hay servicios disponibles para elegir.'),
      findsOneWidget,
    );
  });

  group('ubicación', () {
    Future<void> openPicker(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Fijar en el mapa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fijar en el mapa'));
      await tester.pumpAndSettle();
    }

    BusinessDraft savedDraft() =>
        (verify(
                  () => bloc.add(captureAny(that: isA<BusinessProfileSaved>())),
                ).captured.single
                as BusinessProfileSaved)
            .draft;

    testWidgets('sin ubicación invita a fijarla', (tester) async {
      await pump(tester, empty);
      expect(find.text('Sin fijar'), findsOneWidget);
      expect(find.text('Sin ubicación fijada'), findsOneWidget);
    });

    testWidgets('con "Usar mi ubicación" fija el punto y se guarda', (
      tester,
    ) async {
      await pump(tester, empty);
      await openPicker(tester);

      expect(find.text('Ubicación de tu sede'), findsOneWidget);
      // Vista de la ciudad (Florencia): aún lejos para confirmar.
      expect(
        find.text('Acércate más al mapa para ubicar el punto exacto.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ButtonStyleButton>(
              find.byKey(const Key('confirm-location')),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.byKey(const Key('use-my-location')));
      await tester.pumpAndSettle();
      expect(find.text('Punto de llegada: 2.44480, -76.61470'), findsOneWidget);
      await tester.tap(find.text('Confirmar ubicación'));
      await tester.pumpAndSettle();

      expect(find.text('Fijada'), findsOneWidget);
      expect(find.text('2.44480, -76.61470'), findsOneWidget);
      // El aviso "Ubicación fijada" se cierra solo y deja ver el botón.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await fillRequired(tester);
      await tester.tap(find.text('Guardar negocio y continuar'));
      await tester.pump();
      expect(savedDraft().location, const GeoPoint(2.4448, -76.6147));
    });

    testWidgets('permiso bloqueado: avisa y ofrece abrir ajustes', (
      tester,
    ) async {
      location.error = DeviceLocationError.deniedForever;
      await pump(tester, empty);
      await openPicker(tester);
      await tester.tap(find.byKey(const Key('use-my-location')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'El permiso de ubicación está bloqueado. Actívalo en los ajustes.',
        ),
        findsWidgets,
      );
      // El aviso se replica en cada pantalla; se toca el del mapa (arriba).
      await tester.tap(find.text('Ajustes').last);
      expect(location.settingsOpened, isTrue);
    });

    testWidgets('cerrar el mapa no cambia nada', (tester) async {
      await pump(tester, empty);
      await openPicker(tester);
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(find.text('Sin fijar'), findsOneWidget);
    });

    testWidgets('con ubicación guardada la muestra y se puede quitar', (
      tester,
    ) async {
      const withLocation = Business(
        id: 'b1',
        name: 'El Campín',
        address: 'Carrera 11 # 18-45',
        neighborhood: 'Centro',
        location: GeoPoint(4.6097, -74.0817),
      );
      await pump(tester, empty.copyWith(business: withLocation));

      expect(find.text('Fijada'), findsOneWidget);
      expect(find.text('4.60970, -74.08170'), findsOneWidget);

      await tester.ensureVisible(find.text('Quitar').last);
      await tester.tap(find.text('Quitar').last);
      await tester.pump();
      expect(find.text('Sin fijar'), findsOneWidget);

      await tester.tap(find.text('Guardar cambios'));
      await tester.pump();
      expect(savedDraft().location, isNull);
    });
  });
}
