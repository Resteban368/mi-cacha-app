import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/catalogs/domain/usecases/get_catalogs.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/business_profile/domain/entities/online_booking_link.dart';
import 'package:mi_cancha/features/business_profile/domain/usecases/get_my_business.dart';
import 'package:mi_cancha/features/business_profile/domain/usecases/get_online_booking_link.dart';
import 'package:mi_cancha/features/business_profile/domain/entities/business.dart';
import 'package:mi_cancha/core/media/image_upload.dart';
import 'package:mi_cancha/features/business_profile/domain/usecases/business_photo_usecases.dart';
import 'package:mi_cancha/features/business_profile/domain/usecases/save_business.dart';
import 'package:mi_cancha/features/business_profile/presentation/bloc/business_profile_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../business_fixtures.dart';

class _MockGetMyBusiness extends Mock implements GetMyBusiness {}

class _MockSaveBusiness extends Mock implements SaveBusiness {}

class _MockAdd extends Mock implements AddBusinessPhoto {}

class _MockRemove extends Mock implements RemoveBusinessPhoto {}

class _MockReorder extends Mock implements ReorderBusinessPhotos {}

class _MockGetCatalogs extends Mock implements GetCatalogs {}

class _MockGetBookingLink extends Mock implements GetOnlineBookingLink {}

void main() {
  late _MockGetMyBusiness getMyBusiness;
  late _MockSaveBusiness saveBusiness;
  late _MockAdd addPhoto;
  late _MockRemove removePhoto;
  late _MockReorder reorderPhotos;
  late _MockGetCatalogs getCatalogs;
  late _MockGetBookingLink getBookingLink;

  const link = OnlineBookingLink(
    url: 'https://mi-cancha-api.vercel.app/reservar/el-campin',
    slug: 'el-campin',
    enabled: true,
    bookingAvailable: true,
  );

  final photo = ImageUpload(
    bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]),
    fileName: 'portada.jpg',
  );

  /// El negocio del fixture con [count] fotos (p1, p2, …).
  Business withPhotos(int count) {
    final photos = [
      for (var i = 1; i <= count; i++)
        BusinessPhoto(id: 'p$i', url: 'https://api.test/p$i.jpg'),
    ];
    return Business(
      id: business.id,
      name: business.name,
      address: business.address,
      neighborhood: business.neighborhood,
      imageUrl: photos.firstOrNull?.url,
      photos: photos,
    );
  }

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(draft);
    registerFallbackValue(
      ImageUpload(bytes: Uint8List(0), fileName: 'fallback.jpg'),
    );
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    getMyBusiness = _MockGetMyBusiness();
    saveBusiness = _MockSaveBusiness();
    addPhoto = _MockAdd();
    removePhoto = _MockRemove();
    reorderPhotos = _MockReorder();
    getCatalogs = _MockGetCatalogs();
    getBookingLink = _MockGetBookingLink();
    when(() => getCatalogs(any())).thenAnswer((_) async => catalogs);
    when(() => getBookingLink(any())).thenAnswer((_) async => link);
  });

  BusinessProfileBloc build() => BusinessProfileBloc(
    getMyBusiness: getMyBusiness,
    saveBusiness: saveBusiness,
    addPhoto: addPhoto,
    removePhoto: removePhoto,
    reorderPhotos: reorderPhotos,
    getCatalogs: getCatalogs,
    getBookingLink: getBookingLink,
  );

  const ready = BusinessProfileState(status: BusinessProfileStatus.ready);

  blocTest<BusinessProfileBloc, BusinessProfileState>(
    'sin negocio queda listo, vacío y con el catálogo de servicios',
    setUp: () => when(() => getMyBusiness(any())).thenAnswer((_) async => null),
    build: build,
    act: (bloc) => bloc.add(const BusinessProfileRequested()),
    expect: () => const [
      BusinessProfileState(status: BusinessProfileStatus.loading),
      BusinessProfileState(
        status: BusinessProfileStatus.ready,
        amenityOptions: amenityCatalog,
        amenityStatus: AmenityCatalogStatus.ready,
      ),
    ],
  );

  blocTest<BusinessProfileBloc, BusinessProfileState>(
    'si el catálogo falla, el formulario igual queda listo',
    setUp: () {
      when(() => getMyBusiness(any())).thenAnswer((_) async => business);
      when(() => getCatalogs(any())).thenThrow(Exception());
    },
    build: build,
    act: (bloc) => bloc.add(const BusinessProfileRequested()),
    skip: 1,
    expect: () => const [
      BusinessProfileState(
        status: BusinessProfileStatus.ready,
        business: business,
        amenityStatus: AmenityCatalogStatus.failure,
      ),
      // Después carga el link de reservas.
      BusinessProfileState(
        status: BusinessProfileStatus.ready,
        business: business,
        amenityStatus: AmenityCatalogStatus.failure,
        bookingLinkStatus: OnlineBookingStatus.loading,
      ),
      BusinessProfileState(
        status: BusinessProfileStatus.ready,
        business: business,
        amenityStatus: AmenityCatalogStatus.failure,
        bookingLink: link,
        bookingLinkStatus: OnlineBookingStatus.ready,
      ),
    ],
  );

  blocTest<BusinessProfileBloc, BusinessProfileState>(
    'reintentar el catálogo',
    build: build,
    seed: () => ready.copyWith(amenityStatus: AmenityCatalogStatus.failure),
    act: (bloc) => bloc.add(const BusinessAmenitiesRequested()),
    expect: () => [
      ready,
      ready.copyWith(
        amenityOptions: amenityCatalog,
        amenityStatus: AmenityCatalogStatus.ready,
      ),
    ],
  );

  blocTest<BusinessProfileBloc, BusinessProfileState>(
    'solo guarda servicios que siguen activos en el catálogo',
    setUp: () =>
        when(() => saveBusiness(any())).thenAnswer((_) async => business),
    build: build,
    seed: () => ready.copyWith(
      amenityOptions: amenityCatalog,
      amenityStatus: AmenityCatalogStatus.ready,
    ),
    act: (bloc) => bloc.add(
      BusinessProfileSaved(
        draft.copyWith(amenities: {'WIFI', 'DESACTIVADO_EN_PANEL'}),
      ),
    ),
    verify: (_) => verify(
      () => saveBusiness(draft.copyWith(amenities: {'WIFI'})),
    ).called(1),
  );

  blocTest<BusinessProfileBloc, BusinessProfileState>(
    'error al cargar',
    setUp: () => when(() => getMyBusiness(any())).thenThrow(Exception()),
    build: build,
    act: (bloc) => bloc.add(const BusinessProfileRequested()),
    expect: () => const [
      BusinessProfileState(status: BusinessProfileStatus.loading),
      BusinessProfileState(status: BusinessProfileStatus.failure),
    ],
  );

  blocTest<BusinessProfileBloc, BusinessProfileState>(
    'guardar sin negocio previo => created',
    setUp: () =>
        when(() => saveBusiness(any())).thenAnswer((_) async => business),
    build: build,
    seed: () => ready,
    act: (bloc) => bloc.add(const BusinessProfileSaved(draft)),
    expect: () => const [
      BusinessProfileState(
        status: BusinessProfileStatus.ready,
        saveStatus: BusinessSaveStatus.saving,
      ),
      BusinessProfileState(
        status: BusinessProfileStatus.ready,
        business: business,
        saveStatus: BusinessSaveStatus.created,
      ),
      // Recién creado ya tiene link de reservas.
      BusinessProfileState(
        status: BusinessProfileStatus.ready,
        business: business,
        saveStatus: BusinessSaveStatus.created,
        bookingLinkStatus: OnlineBookingStatus.loading,
      ),
      BusinessProfileState(
        status: BusinessProfileStatus.ready,
        business: business,
        saveStatus: BusinessSaveStatus.created,
        bookingLink: link,
        bookingLinkStatus: OnlineBookingStatus.ready,
      ),
    ],
  );

  blocTest<BusinessProfileBloc, BusinessProfileState>(
    'guardar con negocio existente => updated',
    setUp: () =>
        when(() => saveBusiness(any())).thenAnswer((_) async => business),
    build: build,
    seed: () => const BusinessProfileState(
      status: BusinessProfileStatus.ready,
      business: business,
    ),
    act: (bloc) => bloc.add(const BusinessProfileSaved(draft)),
    skip: 1,
    expect: () => const [
      BusinessProfileState(
        status: BusinessProfileStatus.ready,
        business: business,
        saveStatus: BusinessSaveStatus.updated,
      ),
    ],
  );

  blocTest<BusinessProfileBloc, BusinessProfileState>(
    'doble toque en guardar envía una sola vez (droppable)',
    setUp: () => when(() => saveBusiness(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return business;
    }),
    build: build,
    seed: () => ready,
    act: (bloc) => bloc
      ..add(const BusinessProfileSaved(draft))
      ..add(const BusinessProfileSaved(draft)),
    wait: const Duration(milliseconds: 60),
    verify: (_) => verify(() => saveBusiness(any())).called(1),
  );

  blocTest<BusinessProfileBloc, BusinessProfileState>(
    'error al guardar',
    setUp: () => when(() => saveBusiness(any())).thenThrow(Exception()),
    build: build,
    seed: () => ready,
    act: (bloc) => bloc.add(const BusinessProfileSaved(draft)),
    skip: 1,
    expect: () => const [
      BusinessProfileState(
        status: BusinessProfileStatus.ready,
        saveStatus: BusinessSaveStatus.failure,
      ),
    ],
  );

  group('link de reservas en línea', () {
    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'sin negocio no se pide',
      setUp: () =>
          when(() => getMyBusiness(any())).thenAnswer((_) async => null),
      build: build,
      act: (bloc) => bloc.add(const BusinessProfileRequested()),
      verify: (bloc) {
        verifyNever(() => getBookingLink(any()));
        expect(bloc.state.bookingLinkStatus, OnlineBookingStatus.idle);
      },
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'con negocio lo carga después del formulario',
      setUp: () =>
          when(() => getMyBusiness(any())).thenAnswer((_) async => business),
      build: build,
      act: (bloc) => bloc.add(const BusinessProfileRequested()),
      verify: (bloc) {
        expect(bloc.state.status, BusinessProfileStatus.ready);
        expect(bloc.state.bookingLink, link);
        expect(bloc.state.bookingLinkStatus, OnlineBookingStatus.ready);
      },
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'si falla, el formulario sigue listo y se puede reintentar',
      setUp: () {
        when(() => getMyBusiness(any())).thenAnswer((_) async => business);
        when(() => getBookingLink(any())).thenThrow(Exception());
      },
      build: build,
      act: (bloc) async {
        bloc.add(const BusinessProfileRequested());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.status, BusinessProfileStatus.ready);
        expect(bloc.state.bookingLinkStatus, OnlineBookingStatus.failure);

        when(() => getBookingLink(any())).thenAnswer((_) async => link);
        bloc.add(const BusinessOnlineBookingRequested());
      },
      verify: (bloc) {
        expect(bloc.state.bookingLink, link);
        expect(bloc.state.bookingLinkStatus, OnlineBookingStatus.ready);
      },
    );
  });

  group('galería de fotos', () {
    final existing = BusinessProfileState(
      status: BusinessProfileStatus.ready,
      business: withPhotos(2),
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'agregar: la sube y toma el negocio que devuelve la API',
      setUp: () =>
          when(() => addPhoto(any())).thenAnswer((_) async => withPhotos(3)),
      build: build,
      seed: () => existing,
      act: (bloc) => bloc.add(BusinessPhotoPicked(photo)),
      expect: () => [
        existing.copyWith(photoStatus: BusinessPhotoStatus.uploading),
        existing.copyWith(
          business: withPhotos(3),
          photoStatus: BusinessPhotoStatus.uploaded,
        ),
      ],
      verify: (_) => verify(() => addPhoto(photo)).called(1),
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'límite de 5: no llama a la API y avisa',
      build: build,
      seed: () => existing.copyWith(business: withPhotos(5)),
      act: (bloc) => bloc.add(BusinessPhotoPicked(photo)),
      expect: () => [
        existing.copyWith(
          business: withPhotos(5),
          photoStatus: BusinessPhotoStatus.limitReached,
        ),
      ],
      verify: (_) => verifyNever(() => addPhoto(any())),
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'más de 4 MB: avisa sin subirla',
      build: build,
      seed: () => existing,
      act: (bloc) => bloc.add(
        BusinessPhotoPicked(
          ImageUpload(
            bytes: Uint8List(ImageUpload.maxBytes + 1)
              ..setAll(0, [0xff, 0xd8, 0xff]),
            fileName: 'grande.jpg',
          ),
        ),
      ),
      expect: () => [
        existing.copyWith(photoStatus: BusinessPhotoStatus.tooLarge),
      ],
      verify: (_) => verifyNever(() => addPhoto(any())),
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'archivo que no es JPG ni PNG',
      build: build,
      seed: () => existing,
      act: (bloc) => bloc.add(
        BusinessPhotoPicked(
          ImageUpload(
            bytes: Uint8List.fromList('GIF89a'.codeUnits),
            fileName: 'a.gif',
          ),
        ),
      ),
      expect: () => [
        existing.copyWith(photoStatus: BusinessPhotoStatus.invalidType),
      ],
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'error de la API al subir',
      setUp: () => when(() => addPhoto(any())).thenThrow(Exception()),
      build: build,
      seed: () => existing,
      act: (bloc) => bloc.add(BusinessPhotoPicked(photo)),
      skip: 1,
      expect: () => [
        existing.copyWith(photoStatus: BusinessPhotoStatus.failure),
      ],
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'sin negocio queda pendiente y se sube al registrarlo',
      setUp: () {
        when(() => saveBusiness(any())).thenAnswer((_) async => business);
        when(() => addPhoto(any())).thenAnswer((_) async => withPhotos(1));
      },
      build: build,
      seed: () => ready,
      act: (bloc) => bloc
        ..add(BusinessPhotoPicked(photo))
        ..add(const BusinessProfileSaved(draft)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        verify(() => addPhoto(photo)).called(1);
        expect(bloc.state.business, withPhotos(1));
        expect(bloc.state.pendingPhoto, isNull);
        expect(bloc.state.saveStatus, BusinessSaveStatus.created);
        expect(bloc.state.photoStatus, BusinessPhotoStatus.idle);
      },
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'si la foto falla al registrar, el negocio igual queda creado',
      setUp: () {
        when(() => saveBusiness(any())).thenAnswer((_) async => business);
        when(() => addPhoto(any())).thenThrow(Exception());
      },
      build: build,
      seed: () => ready.copyWith(pendingPhoto: () => photo),
      act: (bloc) => bloc.add(const BusinessProfileSaved(draft)),
      verify: (bloc) {
        expect(bloc.state.business, business);
        expect(bloc.state.saveStatus, BusinessSaveStatus.created);
        expect(bloc.state.photoStatus, BusinessPhotoStatus.failure);
        expect(bloc.state.pendingPhoto, isNull);
      },
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'quitar: envía el id de la foto',
      setUp: () =>
          when(() => removePhoto(any())).thenAnswer((_) async => withPhotos(1)),
      build: build,
      seed: () => existing,
      act: (bloc) => bloc.add(const BusinessPhotoRemoved('p2')),
      expect: () => [
        existing.copyWith(photoStatus: BusinessPhotoStatus.removing),
        existing.copyWith(
          business: withPhotos(1),
          photoStatus: BusinessPhotoStatus.removed,
        ),
      ],
      verify: (_) => verify(() => removePhoto('p2')).called(1),
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'quitar una foto pendiente no llama a la API',
      build: build,
      seed: () => ready.copyWith(pendingPhoto: () => photo),
      act: (bloc) => bloc.add(const BusinessPhotoRemoved()),
      expect: () => [ready],
      verify: (_) => verifyNever(() => removePhoto(any())),
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'reordenar (hacer portada): envía todos los ids en el nuevo orden',
      setUp: () => when(
        () => reorderPhotos(any()),
      ).thenAnswer((_) async => withPhotos(2)),
      build: build,
      seed: () => existing,
      act: (bloc) => bloc.add(const BusinessPhotosReordered(['p2', 'p1'])),
      expect: () => [
        existing.copyWith(photoStatus: BusinessPhotoStatus.reordering),
        existing.copyWith(photoStatus: BusinessPhotoStatus.reordered),
      ],
      verify: (_) => verify(() => reorderPhotos(['p2', 'p1'])).called(1),
    );

    for (final (name, ids) in [
      ('falta una foto', ['p2']),
      ('ids repetidos', ['p1', 'p1']),
      ('id que no es del negocio', ['p1', 'p9']),
      ('el mismo orden', ['p1', 'p2']),
    ]) {
      blocTest<BusinessProfileBloc, BusinessProfileState>(
        'reordenar con $name no llama a la API',
        build: build,
        seed: () => existing,
        act: (bloc) => bloc.add(BusinessPhotosReordered(ids)),
        expect: () => const <BusinessProfileState>[],
        verify: (_) => verifyNever(() => reorderPhotos(any())),
      );
    }
  });
}
