import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/catalogs/data/datasources/catalogs_api_data_source.dart';
import 'package:mi_cancha/core/catalogs/data/repositories/catalogs_repository_impl.dart';
import 'package:mi_cancha/core/catalogs/domain/entities/catalog_geography.dart';
import 'package:mi_cancha/core/network/api_exception.dart';

import '../../helpers/api_dio.dart';
import '../../helpers/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter adapter;
  late CatalogsRepositoryImpl repository;

  setUp(() {
    adapter = FakeHttpAdapter((options) {
      return switch (options.path) {
        '/catalogs/departments' => (
          200,
          [
            {'id': 'd05', 'code': '05', 'name': 'Antioquia'},
            {'id': 'd11', 'code': '11', 'name': 'Bogotá, D.C.'},
          ],
        ),
        '/catalogs/departments/d05/cities' => (
          200,
          [
            {'id': 'c05001', 'code': '05001', 'name': 'Medellín'},
          ],
        ),
        _ => (404, {'statusCode': 404}),
      };
    });
    repository = CatalogsRepositoryImpl(CatalogsApiDataSource(apiDio(adapter)));
  });

  test('lee los departamentos', () async {
    expect(await repository.getDepartments(), const [
      CatalogDepartment(id: 'd05', code: '05', name: 'Antioquia'),
      CatalogDepartment(id: 'd11', code: '11', name: 'Bogotá, D.C.'),
    ]);
  });

  test('lee los municipios de un departamento', () async {
    expect(await repository.getCities('d05'), const [
      CatalogCity(id: 'c05001', code: '05001', name: 'Medellín'),
    ]);
    expect(adapter.requests.single.path, '/catalogs/departments/d05/cities');
  });

  test('guarda en memoria: no los vuelve a pedir en la sesión', () async {
    await repository.getDepartments();
    await repository.getDepartments();
    await repository.getCities('d05');
    await repository.getCities('d05');

    expect(adapter.requests.map((r) => r.path), [
      '/catalogs/departments',
      '/catalogs/departments/d05/cities',
    ]);
  });

  test('un error no se guarda: el reintento vuelve a pedirlos', () async {
    final ok = adapter.handler;
    adapter.handler = offline;
    await expectLater(
      repository.getDepartments(),
      throwsA(isA<ApiException>()),
    );

    adapter.handler = ok;
    expect(await repository.getDepartments(), hasLength(2));
    expect(adapter.requests, hasLength(2));
  });
}
