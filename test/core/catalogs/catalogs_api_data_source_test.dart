import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/catalogs/data/datasources/catalogs_api_data_source.dart';
import 'package:mi_cancha/core/catalogs/data/repositories/catalogs_repository_impl.dart';
import 'package:mi_cancha/core/catalogs/domain/usecases/get_catalogs.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';

import '../../helpers/api_dio.dart';
import '../../helpers/fake_http_adapter.dart';

void main() {
  group('Catalogs API', () {
    test(
      'getCatalogs mapea correctamente amenities y paymentMethods',
      () async {
        final adapter = FakeHttpAdapter((options) {
          expect(options.path, '/catalogs');
          return (
            200,
            {
              'amenities': [
                {
                  'id': 'a1',
                  'code': 'PARQUEADERO',
                  'name': 'Parqueadero',
                  'active': true,
                  'sortOrder': 1,
                },
                {
                  'id': 'a2',
                  'code': 'WIFI',
                  'name': 'WiFi Gratis',
                  'active': true,
                  'sortOrder': 6,
                },
              ],
              'paymentMethods': [
                {
                  'id': 'p1',
                  'code': 'EFECTIVO',
                  'name': 'Efectivo',
                  'active': true,
                  'sortOrder': 1,
                  'requiresReference': false,
                },
                {
                  'id': 'p2',
                  'code': 'NEQUI',
                  'name': 'Nequi',
                  'active': true,
                  'sortOrder': 2,
                  'requiresReference': true,
                },
                {
                  'id': 'p3',
                  'code': 'BRE_B',
                  'name': 'bre-b',
                  'active': true,
                  'sortOrder': 1,
                  'requiresReference': true,
                },
              ],
            },
          );
        });

        final dio = apiDio(adapter);
        final dataSource = CatalogsApiDataSource(dio);

        final catalogs = await dataSource.getCatalogs();

        expect(catalogs.amenities.length, 2);
        expect(catalogs.amenities.first.code, 'PARQUEADERO');
        expect(catalogs.amenities.first.name, 'Parqueadero');
        expect(catalogs.amenities.first.active, isTrue);

        expect(catalogs.paymentMethods.length, 3);
        expect(catalogs.paymentMethods[0].code, 'EFECTIVO');
        expect(catalogs.paymentMethods[0].requiresReference, isFalse);
        expect(catalogs.paymentMethods[1].code, 'NEQUI');
        expect(catalogs.paymentMethods[1].requiresReference, isTrue);
        expect(catalogs.paymentMethods[2].code, 'BRE_B');
        expect(catalogs.paymentMethods[2].requiresReference, isTrue);
      },
    );

    test('GetCatalogs usecase delega al repositorio', () async {
      final adapter = FakeHttpAdapter(
        (_) => (200, {'amenities': [], 'paymentMethods': []}),
      );
      final dio = apiDio(adapter);
      final dataSource = CatalogsApiDataSource(dio);
      final repository = CatalogsRepositoryImpl(dataSource);
      final usecase = GetCatalogs(repository);

      final result = await usecase(const NoParams());
      expect(result.amenities, isEmpty);
      expect(result.paymentMethods, isEmpty);
    });
  });
}
