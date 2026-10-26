import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/location/geo_point.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/business_courts/domain/entities/court.dart';
import 'package:mi_cancha/features/business_courts/domain/repositories/courts_repository.dart';
import 'package:mi_cancha/features/business_profile/domain/entities/business.dart';
import 'package:mi_cancha/features/business_profile/domain/repositories/business_repository.dart';
import 'package:mi_cancha/features/business_setup/domain/entities/setup_progress.dart';
import 'package:mi_cancha/features/business_setup/domain/usecases/get_setup_progress.dart';
import 'package:mocktail/mocktail.dart';

class _MockBusinessRepository extends Mock implements BusinessRepository {}

class _MockCourtsRepository extends Mock implements CourtsRepository {}

const _city = City(
  id: 'c1',
  name: 'Florencia',
  departmentId: 'd1',
  departmentName: 'Caquetá',
);

const completeBusiness = Business(
  id: 'b1',
  name: 'El Campín',
  address: 'Carrera 11 # 18-45',
  neighborhood: 'Centro',
  city: _city,
  location: GeoPoint(1.61, -75.6),
  photos: [BusinessPhoto(id: 'p1', url: 'https://x/1.jpg')],
);

Court court({required bool bookable}) => Court(
  id: 'k1',
  name: 'Cancha 1',
  sport: null,
  isActive: true,
  isComplete: bookable,
  isBookable: bookable,
);

void main() {
  late _MockBusinessRepository business;
  late _MockCourtsRepository courts;
  late GetSetupProgress useCase;

  setUp(() {
    business = _MockBusinessRepository();
    courts = _MockCourtsRepository();
    useCase = GetSetupProgress(business, courts);
  });

  test('sin negocio pide todos los datos', () async {
    when(() => business.getMyBusiness()).thenAnswer((_) async => null);
    expect(
      await useCase(const NoParams()),
      const SetupProgress(
        SetupStep.business,
        missing: BusinessRequirement.values,
      ),
    );
    verifyNever(() => courts.getCourts());
  });

  test('con el negocio incompleto dice qué falta', () async {
    when(() => business.getMyBusiness()).thenAnswer(
      (_) async => const Business(
        id: 'b1',
        name: 'El Campín',
        address: 'Carrera 11 # 18-45',
        neighborhood: 'Centro',
        city: _city,
      ),
    );
    expect(
      await useCase(const NoParams()),
      const SetupProgress(
        SetupStep.business,
        missing: [BusinessRequirement.location, BusinessRequirement.photo],
      ),
    );
  });

  test('la portada sola cuenta como foto', () {
    const withCover = Business(
      id: 'b1',
      name: 'El Campín',
      address: 'Carrera 11 # 18-45',
      neighborhood: 'Centro',
      city: _city,
      location: GeoPoint(1.61, -75.6),
      imageUrl: 'https://x/portada.jpg',
    );
    expect(withCover.missingRequirements, isEmpty);
  });

  test('negocio completo sin cancha lista pasa al paso de canchas', () async {
    when(
      () => business.getMyBusiness(),
    ).thenAnswer((_) async => completeBusiness);
    when(
      () => courts.getCourts(),
    ).thenAnswer((_) async => [court(bookable: false)]);
    expect(
      await useCase(const NoParams()),
      const SetupProgress(SetupStep.court),
    );
  });

  test('con una cancha lista para reservas termina', () async {
    when(
      () => business.getMyBusiness(),
    ).thenAnswer((_) async => completeBusiness);
    when(
      () => courts.getCourts(),
    ).thenAnswer((_) async => [court(bookable: false), court(bookable: true)]);
    expect(await useCase(const NoParams()), SetupProgress.done);
  });
}
