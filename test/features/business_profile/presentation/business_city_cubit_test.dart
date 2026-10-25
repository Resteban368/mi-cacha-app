import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/catalogs/domain/entities/catalog_geography.dart';
import 'package:mi_cancha/core/catalogs/domain/usecases/geography_usecases.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/business_profile/domain/entities/business.dart';
import 'package:mi_cancha/features/business_profile/presentation/bloc/business_city_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetDepartments extends Mock implements GetDepartments {}

class _MockGetCities extends Mock implements GetCities {}

void main() {
  const antioquia = CatalogDepartment(id: 'd05', code: '05', name: 'Antioquia');
  const caqueta = CatalogDepartment(id: 'd18', code: '18', name: 'Caquetá');
  const medellin = CatalogCity(id: 'c05001', code: '05001', name: 'Medellín');
  const florencia = CatalogCity(id: 'c18001', code: '18001', name: 'Florencia');

  late _MockGetDepartments getDepartments;
  late _MockGetCities getCities;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    getDepartments = _MockGetDepartments();
    getCities = _MockGetCities();
    when(
      () => getDepartments(any()),
    ).thenAnswer((_) async => const [antioquia, caqueta]);
    when(() => getCities('d05')).thenAnswer((_) async => const [medellin]);
    when(() => getCities('d18')).thenAnswer((_) async => const [florencia]);
  });

  BusinessCityCubit build() =>
      BusinessCityCubit(getDepartments: getDepartments, getCities: getCities);

  const ready = BusinessCityState(
    departmentsStatus: GeographyLoad.ready,
    departments: [antioquia, caqueta],
  );

  blocTest<BusinessCityCubit, BusinessCityState>(
    'al crear carga los departamentos sin nada elegido',
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => const [
      BusinessCityState(departmentsStatus: GeographyLoad.loading),
      ready,
    ],
    verify: (_) => verifyNever(() => getCities(any())),
  );

  blocTest<BusinessCityCubit, BusinessCityState>(
    'si fallan los departamentos, reintentar los vuelve a pedir',
    setUp: () => when(() => getDepartments(any())).thenThrow(Exception()),
    build: build,
    act: (cubit) async {
      await cubit.load();
      expect(cubit.state.departmentsStatus, GeographyLoad.failure);
      when(
        () => getDepartments(any()),
      ).thenAnswer((_) async => const [antioquia]);
      await cubit.retryDepartments();
    },
    verify: (cubit) {
      expect(cubit.state.departmentsStatus, GeographyLoad.ready);
      expect(cubit.state.departments, const [antioquia]);
    },
  );

  blocTest<BusinessCityCubit, BusinessCityState>(
    'elegir el departamento carga sus ciudades',
    build: build,
    seed: () => ready,
    act: (cubit) => cubit.selectDepartment(antioquia),
    expect: () => [
      ready.copyWith(department: () => antioquia),
      ready.copyWith(
        department: () => antioquia,
        citiesStatus: GeographyLoad.loading,
      ),
      ready.copyWith(
        department: () => antioquia,
        citiesStatus: GeographyLoad.ready,
        cities: const [medellin],
      ),
    ],
  );

  blocTest<BusinessCityCubit, BusinessCityState>(
    'cambiar el departamento limpia la ciudad',
    build: build,
    seed: () => ready.copyWith(
      department: () => antioquia,
      citiesStatus: GeographyLoad.ready,
      cities: const [medellin],
      city: () => medellin,
    ),
    act: (cubit) => cubit.selectDepartment(caqueta),
    verify: (cubit) {
      expect(cubit.state.department, caqueta);
      expect(cubit.state.city, isNull);
      expect(cubit.state.cities, const [florencia]);
    },
  );

  blocTest<BusinessCityCubit, BusinessCityState>(
    'el mismo departamento no limpia ni vuelve a pedir',
    build: build,
    seed: () => ready.copyWith(
      department: () => antioquia,
      citiesStatus: GeographyLoad.ready,
      cities: const [medellin],
      city: () => medellin,
    ),
    act: (cubit) => cubit.selectDepartment(antioquia),
    expect: () => const <BusinessCityState>[],
    verify: (_) => verifyNever(() => getCities(any())),
  );

  blocTest<BusinessCityCubit, BusinessCityState>(
    'las ciudades de un departamento anterior que llegan tarde se descartan',
    setUp: () {
      final slow = Completer<List<CatalogCity>>();
      when(() => getCities('d05')).thenAnswer((_) => slow.future);
      Future<void>.delayed(
        const Duration(milliseconds: 20),
        () => slow.complete(const [medellin]),
      );
    },
    build: build,
    seed: () => ready,
    act: (cubit) async {
      unawaited(cubit.selectDepartment(antioquia));
      await cubit.selectDepartment(caqueta);
      await Future<void>.delayed(const Duration(milliseconds: 40));
    },
    verify: (cubit) {
      expect(cubit.state.department, caqueta);
      expect(cubit.state.cities, const [florencia]);
    },
  );

  group('validación de obligatorios', () {
    blocTest<BusinessCityCubit, BusinessCityState>(
      'sin departamento ni ciudad marca los dos',
      build: build,
      seed: () => ready,
      act: (cubit) => expect(cubit.validate(), isFalse),
      verify: (cubit) {
        expect(cubit.state.departmentError, 'Elige el departamento');
        expect(cubit.state.cityError, 'Elige la ciudad');
      },
    );

    blocTest<BusinessCityCubit, BusinessCityState>(
      'con departamento y sin ciudad marca solo la ciudad',
      build: build,
      seed: () => ready.copyWith(department: () => antioquia),
      act: (cubit) => expect(cubit.validate(), isFalse),
      verify: (cubit) {
        expect(cubit.state.departmentError, isNull);
        expect(cubit.state.cityError, 'Elige la ciudad');
      },
    );

    blocTest<BusinessCityCubit, BusinessCityState>(
      'con los dos es válido',
      build: build,
      seed: () =>
          ready.copyWith(department: () => antioquia, city: () => medellin),
      act: (cubit) => expect(cubit.validate(), isTrue),
      verify: (cubit) {
        expect(cubit.state.departmentError, isNull);
        expect(cubit.state.cityError, isNull);
      },
    );

    test('antes de intentar guardar no muestra errores', () {
      expect(ready.departmentError, isNull);
      expect(ready.cityError, isNull);
    });
  });

  blocTest<BusinessCityCubit, BusinessCityState>(
    'al editar precarga el departamento y la ciudad actuales',
    build: build,
    act: (cubit) => cubit.load(
      initial: const City(
        id: 'c05001',
        name: 'Medellín',
        departmentId: 'd05',
        departmentName: 'Antioquia',
      ),
    ),
    verify: (cubit) {
      expect(cubit.state.department, antioquia);
      expect(cubit.state.city, medellin);
      expect(cubit.state.cities, const [medellin]);
      expect(cubit.state.citiesStatus, GeographyLoad.ready);
    },
  );
}
