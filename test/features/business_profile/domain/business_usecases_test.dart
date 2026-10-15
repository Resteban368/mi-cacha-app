import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/business_profile/domain/entities/business.dart';
import 'package:mi_cancha/features/business_profile/domain/repositories/business_repository.dart';
import 'package:mi_cancha/features/business_profile/domain/usecases/get_my_business.dart';
import 'package:mi_cancha/features/business_profile/domain/usecases/save_business.dart';
import 'package:mocktail/mocktail.dart';

import '../business_fixtures.dart';

class _MockRepository extends Mock implements BusinessRepository {}

void main() {
  setUpAll(() => registerFallbackValue(draft));

  late _MockRepository repository;
  setUp(() => repository = _MockRepository());

  test('GetMyBusiness devuelve null sin negocio creado', () async {
    when(repository.getMyBusiness).thenAnswer((_) async => null);
    expect(await GetMyBusiness(repository)(const NoParams()), isNull);
  });

  test('SaveBusiness guarda un borrador completo', () async {
    when(() => repository.save(draft)).thenAnswer((_) async => business);
    expect(await SaveBusiness(repository)(draft), business);
  });

  for (final incomplete in const [
    BusinessDraft(name: ' ', address: 'Cra 1', neighborhood: 'Centro'),
    BusinessDraft(name: 'Sede', address: '', neighborhood: 'Centro'),
    BusinessDraft(name: 'Sede', address: 'Cra 1', neighborhood: '  '),
  ]) {
    test('SaveBusiness rechaza borradores incompletos: $incomplete', () {
      expect(() => SaveBusiness(repository)(incomplete), throwsArgumentError);
      verifyNever(() => repository.save(any()));
    });
  }
}
