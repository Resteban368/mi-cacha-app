import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/catalogs/domain/usecases/get_catalogs.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/business_profile/domain/usecases/get_my_business.dart';
import 'package:mi_cancha/features/business_profile/domain/entities/business.dart';
import 'package:mi_cancha/core/media/image_upload.dart';
import 'package:mi_cancha/features/business_profile/domain/usecases/remove_business_cover.dart';
import 'package:mi_cancha/features/business_profile/domain/usecases/save_business.dart';
import 'package:mi_cancha/features/business_profile/domain/usecases/upload_business_cover.dart';
import 'package:mi_cancha/features/business_profile/presentation/bloc/business_profile_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../business_fixtures.dart';

class _MockGetMyBusiness extends Mock implements GetMyBusiness {}

class _MockSaveBusiness extends Mock implements SaveBusiness {}

class _MockUpload extends Mock implements UploadBusinessCover {}

class _MockRemove extends Mock implements RemoveBusinessCover {}

class _MockGetCatalogs extends Mock implements GetCatalogs {}

void main() {
  late _MockGetMyBusiness getMyBusiness;
  late _MockSaveBusiness saveBusiness;
  late _MockUpload uploadCover;
  late _MockRemove removeCover;
  late _MockGetCatalogs getCatalogs;

  final photo = ImageUpload(
    bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]),
    fileName: 'portada.jpg',
  );
  const withPhoto = Business(
    id: 'b1',
    name: 'Complejo Deportivo El Campín',
    address: 'Carrera 11 # 18-45',
    neighborhood: 'Centro',
    imageUrl: 'https://api.test/foto.jpg',
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(draft);
    registerFallbackValue(
      ImageUpload(bytes: Uint8List(0), fileName: 'fallback.jpg'),
    );
  });

  setUp(() {
    getMyBusiness = _MockGetMyBusiness();
    saveBusiness = _MockSaveBusiness();
    uploadCover = _MockUpload();
    removeCover = _MockRemove();
    getCatalogs = _MockGetCatalogs();
    when(() => getCatalogs(any())).thenAnswer((_) async => catalogs);
  });

  BusinessProfileBloc build() => BusinessProfileBloc(
    getMyBusiness: getMyBusiness,
    saveBusiness: saveBusiness,
    uploadCover: uploadCover,
    removeCover: removeCover,
    getCatalogs: getCatalogs,
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

  group('foto de portada', () {
    const existing = BusinessProfileState(
      status: BusinessProfileStatus.ready,
      business: business,
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'con negocio la sube al instante',
      setUp: () =>
          when(() => uploadCover(any())).thenAnswer((_) async => withPhoto),
      build: build,
      seed: () => existing,
      act: (bloc) => bloc.add(BusinessCoverPicked(photo)),
      expect: () => [
        existing.copyWith(coverStatus: BusinessCoverStatus.uploading),
        existing.copyWith(
          business: withPhoto,
          coverStatus: BusinessCoverStatus.uploaded,
        ),
      ],
      verify: (_) => verify(() => uploadCover(photo)).called(1),
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'más de 4 MB: avisa sin subirla',
      build: build,
      seed: () => existing,
      act: (bloc) => bloc.add(
        BusinessCoverPicked(
          ImageUpload(
            bytes: Uint8List(ImageUpload.maxBytes + 1)
              ..setAll(0, [0xff, 0xd8, 0xff]),
            fileName: 'grande.jpg',
          ),
        ),
      ),
      expect: () => [
        existing.copyWith(coverStatus: BusinessCoverStatus.tooLarge),
      ],
      verify: (_) => verifyNever(() => uploadCover(any())),
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'archivo que no es JPG ni PNG',
      build: build,
      seed: () => existing,
      act: (bloc) => bloc.add(
        BusinessCoverPicked(
          ImageUpload(
            bytes: Uint8List.fromList('GIF89a'.codeUnits),
            fileName: 'a.gif',
          ),
        ),
      ),
      expect: () => [
        existing.copyWith(coverStatus: BusinessCoverStatus.invalidType),
      ],
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'error de la API al subir',
      setUp: () => when(() => uploadCover(any())).thenThrow(Exception()),
      build: build,
      seed: () => existing,
      act: (bloc) => bloc.add(BusinessCoverPicked(photo)),
      skip: 1,
      expect: () => [
        existing.copyWith(coverStatus: BusinessCoverStatus.failure),
      ],
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'sin negocio queda pendiente y se sube al registrarlo',
      setUp: () {
        when(() => saveBusiness(any())).thenAnswer((_) async => business);
        when(() => uploadCover(any())).thenAnswer((_) async => withPhoto);
      },
      build: build,
      seed: () => ready,
      act: (bloc) => bloc
        ..add(BusinessCoverPicked(photo))
        ..add(const BusinessProfileSaved(draft)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        verify(() => uploadCover(photo)).called(1);
        expect(bloc.state.business, withPhoto);
        expect(bloc.state.pendingCover, isNull);
        expect(bloc.state.saveStatus, BusinessSaveStatus.created);
        expect(bloc.state.coverStatus, BusinessCoverStatus.idle);
      },
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'si la foto falla al registrar, el negocio igual queda creado',
      setUp: () {
        when(() => saveBusiness(any())).thenAnswer((_) async => business);
        when(() => uploadCover(any())).thenThrow(Exception());
      },
      build: build,
      seed: () => ready.copyWith(pendingCover: () => photo),
      act: (bloc) => bloc.add(const BusinessProfileSaved(draft)),
      verify: (bloc) {
        expect(bloc.state.business, business);
        expect(bloc.state.saveStatus, BusinessSaveStatus.created);
        expect(bloc.state.coverStatus, BusinessCoverStatus.failure);
        expect(bloc.state.pendingCover, isNull);
      },
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'quitar la foto subida',
      setUp: () =>
          when(() => removeCover(any())).thenAnswer((_) async => business),
      build: build,
      seed: () => existing.copyWith(business: withPhoto),
      act: (bloc) => bloc.add(const BusinessCoverRemoved()),
      expect: () => [
        existing.copyWith(
          business: withPhoto,
          coverStatus: BusinessCoverStatus.removing,
        ),
        existing.copyWith(coverStatus: BusinessCoverStatus.removed),
      ],
    );

    blocTest<BusinessProfileBloc, BusinessProfileState>(
      'quitar una foto pendiente no llama a la API',
      build: build,
      seed: () => ready.copyWith(pendingCover: () => photo),
      act: (bloc) => bloc.add(const BusinessCoverRemoved()),
      expect: () => [ready],
      verify: (_) => verifyNever(() => removeCover(any())),
    );
  });
}
