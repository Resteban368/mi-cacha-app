import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_profile/data/datasources/business_data_source.dart';
import 'package:mi_cancha/features/business_profile/domain/entities/business.dart';

import '../business_fixtures.dart';

void main() {
  late FakeBusinessDataSource source;
  setUp(() => source = FakeBusinessDataSource(latency: Duration.zero));

  test('arranca sin negocio (estado vacío)', () async {
    expect(await source.getMyBusiness(), isNull);
  });

  test(
    'guardar crea el negocio y luego lo actualiza con el mismo id',
    () async {
      final created = await source.save(draft);
      expect(created, business);
      expect(await source.getMyBusiness(), business);

      final updated = await source.save(
        const BusinessDraft(
          name: '  Sede Norte ',
          address: 'Calle 5',
          neighborhood: 'La Salle',
          description: '   ',
        ),
      );
      expect(updated.id, created.id);
      expect(updated.name, 'Sede Norte');
      expect(updated.description, isNull);
      expect(updated.amenities, isEmpty);
    },
  );
}
