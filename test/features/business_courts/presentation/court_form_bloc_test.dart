import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/catalogs/domain/entities/app_catalogs.dart';
import 'package:mi_cancha/core/catalogs/domain/entities/catalog_court_surface.dart';
import 'package:mi_cancha/core/catalogs/domain/usecases/get_catalogs.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/business_account/domain/entities/business_account.dart';
import 'package:mi_cancha/features/business_account/domain/usecases/get_business_account.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court_failure.dart';
import 'package:mi_cancha/features/business_courts/domain/usecases/create_court.dart';
import 'package:mi_cancha/features/business_courts/domain/usecases/get_courts.dart';
import 'package:mi_cancha/features/business_courts/domain/usecases/remove_court_photo.dart';
import 'package:mi_cancha/features/business_courts/domain/usecases/update_court.dart';
import 'package:mi_cancha/features/business_courts/domain/usecases/upload_court_photo.dart';
import 'package:mi_cancha/features/business_courts/presentation/bloc/court_form_bloc.dart';
import 'package:mi_cancha/features/business_profile/domain/entities/business.dart';
import 'package:mi_cancha/features/business_profile/domain/usecases/get_my_business.dart';
import 'package:mocktail/mocktail.dart';

import '../court_fixtures.dart';

class _MockGetMyBusiness extends Mock implements GetMyBusiness {}

class _MockGetAccount extends Mock implements GetBusinessAccount {}

class _MockCreateCourt extends Mock implements CreateCourt {}

class _MockUpdateCourt extends Mock implements UpdateCourt {}

class _MockRemovePhoto extends Mock implements RemoveCourtPhoto {}

class _MockUploadPhoto extends Mock implements UploadCourtPhoto {}

class _MockGetCourts extends Mock implements GetCourts {}

class _MockGetCatalogs extends Mock implements GetCatalogs {}

const grass = CatalogCourtSurface(
  code: 'GRAMA_SINTETICA',
  name: 'Grama sintética',
  sports: {Sport.futbol, Sport.padel},
);

Subscription plan({int inUse = 0, int limit = 3, bool active = true}) =>
    Subscription(
      planName: 'Básico',
      monthlyPrice: 0,
      since: DateTime(2026),
      nextPayment: DateTime(2026, 2),
      courtLimit: limit,
      courtsInUse: inUse,
      benefits: const [],
      isActive: active,
    );

BusinessAccount account(Subscription? subscription) => BusinessAccount(
  admin: const AdminProfile(
    fullName: 'Cliente dev',
    email: 'dev@test.co',
    phone: '',
    roleLabel: 'Admin',
    verified: true,
  ),
  subscription: subscription,
);

void main() {
  late _MockGetMyBusiness getMyBusiness;
  late _MockGetAccount getAccount;
  late _MockCreateCourt createCourt;
  late _MockUploadPhoto uploadPhoto;
  late _MockGetCourts getCourts;
  late _MockUpdateCourt updateCourt;
  late _MockRemovePhoto removePhoto;
  late _MockGetCatalogs getCatalogs;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(padelDraft);
    registerFallbackValue((
      courtId: 'c1',
      slot: CourtPhotoSlot.main,
      image: jpeg('x.jpg'),
    ));
    registerFallbackValue((courtId: 'c1', draft: padelDraft));
    registerFallbackValue((courtId: 'c1', slot: CourtPhotoSlot.main));
  });

  setUp(() {
    getMyBusiness = _MockGetMyBusiness();
    getAccount = _MockGetAccount();
    createCourt = _MockCreateCourt();
    updateCourt = _MockUpdateCourt();
    removePhoto = _MockRemovePhoto();
    uploadPhoto = _MockUploadPhoto();
    getCourts = _MockGetCourts();
    getCatalogs = _MockGetCatalogs();
    when(() => getCatalogs(any())).thenAnswer(
      (_) async => const AppCatalogs(
        amenities: [],
        paymentMethods: [],
        courtSurfaces: [grass],
      ),
    );
    when(() => getCourts(any())).thenAnswer((_) async => [courtWith({})]);
    when(() => getMyBusiness(any())).thenAnswer(
      (_) async => const Business(
        id: 'b1',
        name: 'cancha dev',
        address: 'Calle 25',
        neighborhood: 'torasso',
      ),
    );
    when(() => getAccount(any())).thenAnswer((_) async => account(plan()));
  });

  CourtFormBloc build() => CourtFormBloc(
    getMyBusiness: getMyBusiness,
    getAccount: getAccount,
    createCourt: createCourt,
    updateCourt: updateCourt,
    uploadPhoto: uploadPhoto,
    removePhoto: removePhoto,
    getCourts: getCourts,
    getCatalogs: getCatalogs,
  );

  /// Sube la foto y devuelve la cancha con las posiciones ya cargadas.
  void uploadsOk() {
    final uploaded = <CourtPhotoSlot>{};
    when(() => uploadPhoto(any())).thenAnswer((invocation) async {
      final params =
          invocation.positionalArguments.single as UploadCourtPhotoParams;
      uploaded.add(params.slot);
      return courtWith({...uploaded});
    });
  }

  group('carga', () {
    blocTest<CourtFormBloc, CourtFormState>(
      'lee la sede y el plan',
      build: build,
      act: (bloc) => bloc.add(const CourtFormStarted()),
      expect: () => [
        const CourtFormState(),
        CourtFormState(
          contextStatus: CourtFormContextStatus.ready,
          venueName: 'cancha dev',
          subscription: plan(),
          planKnown: true,
          existingCourts: [courtWith({})],
          courtSurfaces: const [grass],
        ),
      ],
    );

    blocTest<CourtFormBloc, CourtFormState>(
      'si fallan los catálogos, carga sin superficies',
      setUp: () => when(() => getCatalogs(any())).thenThrow(Exception()),
      build: build,
      act: (bloc) => bloc.add(const CourtFormStarted()),
      skip: 1,
      verify: (bloc) {
        expect(bloc.state.contextStatus, CourtFormContextStatus.ready);
        expect(bloc.state.courtSurfaces, isEmpty);
      },
    );

    blocTest<CourtFormBloc, CourtFormState>(
      'si fallan las canchas existentes, solo no se ofrece copiar',
      setUp: () => when(() => getCourts(any())).thenThrow(Exception()),
      build: build,
      act: (bloc) => bloc.add(const CourtFormStarted()),
      verify: (bloc) {
        expect(bloc.state.contextStatus, CourtFormContextStatus.ready);
        expect(bloc.state.existingCourts, isEmpty);
      },
    );

    blocTest<CourtFormBloc, CourtFormState>(
      'sin negocio registrado',
      setUp: () =>
          when(() => getMyBusiness(any())).thenAnswer((_) async => null),
      build: build,
      act: (bloc) => bloc.add(const CourtFormStarted()),
      verify: (bloc) => expect(bloc.state.hasBusiness, isFalse),
    );

    blocTest<CourtFormBloc, CourtFormState>(
      'si falla el plan igual se puede crear (decide la API)',
      setUp: () => when(() => getAccount(any())).thenThrow(Exception()),
      build: build,
      act: (bloc) => bloc.add(const CourtFormStarted()),
      verify: (bloc) {
        expect(bloc.state.contextStatus, CourtFormContextStatus.ready);
        expect(bloc.state.planKnown, isFalse);
        expect(bloc.state.canActivate, isTrue);
      },
    );
  });

  test('canActivate según el plan', () {
    CourtFormState withPlan(Subscription? s) =>
        CourtFormState(subscription: s, planKnown: true);
    expect(withPlan(plan(inUse: 2)).canActivate, isTrue);
    expect(withPlan(plan(inUse: 3)).canActivate, isFalse);
    expect(withPlan(plan(active: false)).canActivate, isFalse);
    expect(withPlan(null).canActivate, isFalse);
  });

  blocTest<CourtFormBloc, CourtFormState>(
    'crea la cancha y sube sus 2 fotos en orden',
    setUp: () {
      when(() => createCourt(any())).thenAnswer((_) async => courtWith({}));
      uploadsOk();
    },
    build: build,
    act: (bloc) => bloc.add(
      CourtFormSubmitted(draft: padelDraft, uploads: requiredPhotos),
    ),
    verify: (bloc) {
      expect(bloc.state.submitStatus, CourtFormSubmitStatus.success);
      expect(bloc.state.saved!.isBookable, isTrue);
      expect(bloc.state.pendingCourt, isNull);
      final slots = verify(
        () => uploadPhoto(captureAny()),
      ).captured.map((p) => (p as UploadCourtPhotoParams).slot);
      expect(slots, [CourtPhotoSlot.main, CourtPhotoSlot.surface]);
    },
  );

  blocTest<CourtFormBloc, CourtFormState>(
    'avanza la subida de fotos 1/2, 2/2',
    setUp: () {
      when(() => createCourt(any())).thenAnswer((_) async => courtWith({}));
      uploadsOk();
    },
    build: build,
    act: (bloc) => bloc.add(
      CourtFormSubmitted(draft: padelDraft, uploads: requiredPhotos),
    ),
    verify: (_) {},
    expect: () => [
      isA<CourtFormState>().having(
        (s) => s.submitStatus,
        'estado',
        CourtFormSubmitStatus.saving,
      ),
      for (var i = 1; i <= 2; i++)
        isA<CourtFormState>().having((s) => s.photoProgress, 'avance', (i, 2)),
      isA<CourtFormState>().having(
        (s) => s.submitStatus,
        'estado',
        CourtFormSubmitStatus.success,
      ),
    ],
  );

  blocTest<CourtFormBloc, CourtFormState>(
    'límite del plan: muestra el mensaje y no sube fotos',
    setUp: () => when(() => createCourt(any())).thenThrow(
      const CourtException(
        CourtFailure.planLimit,
        message: 'Tu plan Básico permite 3 cancha(s) activa(s)',
      ),
    ),
    build: build,
    act: (bloc) => bloc.add(
      CourtFormSubmitted(draft: padelDraft, uploads: requiredPhotos),
    ),
    verify: (bloc) {
      expect(bloc.state.submitStatus, CourtFormSubmitStatus.failure);
      expect(bloc.state.failure, CourtFailure.planLimit);
      expect(
        bloc.state.failureMessage,
        'Tu plan Básico permite 3 cancha(s) activa(s)',
      );
      verifyNever(() => uploadPhoto(any()));
    },
  );

  blocTest<CourtFormBloc, CourtFormState>(
    'si una foto falla, el reintento no vuelve a crear la cancha',
    setUp: () {
      when(() => createCourt(any())).thenAnswer((_) async => courtWith({}));
      var surfaceAttempts = 0;
      when(() => uploadPhoto(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.single as UploadCourtPhotoParams;
        if (params.slot == CourtPhotoSlot.surface && surfaceAttempts++ == 0) {
          throw Exception('red');
        }
        return switch (params.slot) {
          CourtPhotoSlot.main => courtWith({CourtPhotoSlot.main}),
          _ => courtWith({...createSlots}),
        };
      });
    },
    build: build,
    act: (bloc) async {
      bloc.add(CourtFormSubmitted(draft: padelDraft, uploads: requiredPhotos));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.submitStatus, CourtFormSubmitStatus.photosFailed);
      expect(bloc.state.failedPhotos, {CourtPhotoSlot.surface});
      bloc.add(CourtFormSubmitted(draft: padelDraft, uploads: requiredPhotos));
    },
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      expect(bloc.state.submitStatus, CourtFormSubmitStatus.success);
      verify(() => createCourt(any())).called(1);
      // main, surface (falla) y luego solo surface.
      final slots = verify(
        () => uploadPhoto(captureAny()),
      ).captured.map((p) => (p as UploadCourtPhotoParams).slot);
      expect(slots, [
        CourtPhotoSlot.main,
        CourtPhotoSlot.surface,
        CourtPhotoSlot.surface,
      ]);
    },
  );

  group('editar', () {
    blocTest<CourtFormBloc, CourtFormState>(
      'carga la cancha a editar',
      setUp: () =>
          when(() => getCourts(any())).thenAnswer((_) async => [padelCourt]),
      build: build,
      act: (bloc) => bloc.add(const CourtFormStarted(courtId: 'c-padel')),
      verify: (bloc) {
        expect(bloc.state.contextStatus, CourtFormContextStatus.ready);
        expect(bloc.state.editing, padelCourt);
        expect(bloc.state.isEditing, isTrue);
        // No se ofrece copiar de la misma cancha.
        expect(bloc.state.copySources, isEmpty);
      },
    );

    blocTest<CourtFormBloc, CourtFormState>(
      'cancha que ya no existe',
      build: build,
      act: (bloc) => bloc.add(const CourtFormStarted(courtId: 'otra')),
      verify: (bloc) =>
          expect(bloc.state.contextStatus, CourtFormContextStatus.notFound),
    );

    blocTest<CourtFormBloc, CourtFormState>(
      'sin poder leer las canchas no se puede editar',
      setUp: () => when(() => getCourts(any())).thenThrow(Exception()),
      build: build,
      act: (bloc) => bloc.add(const CourtFormStarted(courtId: 'c-padel')),
      verify: (bloc) =>
          expect(bloc.state.contextStatus, CourtFormContextStatus.failure),
    );

    test('una cancha activa sigue pudiendo estarlo con el plan lleno', () {
      final full = CourtFormState(
        planKnown: true,
        subscription: plan(inUse: 3),
        editing: padelCourt,
      );
      expect(full.canActivate, isTrue);
      final inactive = CourtFormState(
        planKnown: true,
        subscription: plan(inUse: 3),
        editing: const Court(
          id: 'x',
          name: 'X',
          sport: null,
          isActive: false,
          isComplete: true,
          isBookable: false,
        ),
      );
      expect(inactive.canActivate, isFalse);
    });

    blocTest<CourtFormBloc, CourtFormState>(
      'guarda con PATCH, quita y reemplaza fotos sin crear otra cancha',
      setUp: () {
        when(() => updateCourt(any())).thenAnswer((_) async => padelCourt);
        when(() => removePhoto(any())).thenAnswer((_) async => padelCourt);
        when(
          () => uploadPhoto(any()),
        ).thenAnswer((_) async => courtWith({...createSlots}));
      },
      build: build,
      seed: () => CourtFormState(
        contextStatus: CourtFormContextStatus.ready,
        existingCourts: [padelCourt],
        editing: padelCourt,
      ),
      act: (bloc) => bloc.add(
        CourtFormSubmitted(
          draft: padelDraft,
          // MAIN se reemplaza; EXTRA_1 no existe en la cancha y se ignora.
          uploads: {CourtPhotoSlot.main: jpeg('nueva.jpg')},
          removals: const {CourtPhotoSlot.extra1},
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.submitStatus, CourtFormSubmitStatus.success);
        verify(
          () => updateCourt((courtId: 'c-padel', draft: padelDraft)),
        ).called(1);
        verifyNever(() => createCourt(any()));
        verifyNever(() => removePhoto(any()));
        final uploaded = verify(
          () => uploadPhoto(captureAny()),
        ).captured.map((p) => (p as UploadCourtPhotoParams).slot);
        expect(uploaded, [CourtPhotoSlot.main]);
      },
    );

    blocTest<CourtFormBloc, CourtFormState>(
      'quitar una foto que la cancha tiene',
      setUp: () =>
          when(() => updateCourt(any())).thenAnswer((_) async => padelCourt),
      build: build,
      seed: () => CourtFormState(
        contextStatus: CourtFormContextStatus.ready,
        editing: padelCourt,
      ),
      act: (bloc) {
        when(
          () => removePhoto(any()),
        ).thenAnswer((_) async => courtWith(const {}));
        bloc.add(
          CourtFormSubmitted(
            draft: padelDraft,
            removals: const {CourtPhotoSlot.main},
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.saved, courtWith(const {}));
        verify(
          () => removePhoto((courtId: 'c-padel', slot: CourtPhotoSlot.main)),
        ).called(1);
      },
    );
  });
}
