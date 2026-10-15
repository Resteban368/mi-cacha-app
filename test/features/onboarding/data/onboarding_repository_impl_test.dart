import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:mi_cancha/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements OnboardingLocalDataSource {}

void main() {
  late _MockDataSource dataSource;
  late OnboardingRepositoryImpl repository;

  setUp(() {
    dataSource = _MockDataSource();
    repository = OnboardingRepositoryImpl(dataSource);
  });

  test('devuelve el valor guardado', () async {
    when(() => dataSource.readCompleted()).thenAnswer((_) async => true);
    expect(await repository.isCompleted(), isTrue);
  });

  test('si la lectura falla, muestra el onboarding (false)', () async {
    when(() => dataSource.readCompleted()).thenThrow(Exception('x'));
    expect(await repository.isCompleted(), isFalse);
  });

  test('si la escritura falla, no lanza', () async {
    when(() => dataSource.writeCompleted()).thenThrow(Exception('x'));
    await expectLater(repository.markCompleted(), completes);
  });
}
