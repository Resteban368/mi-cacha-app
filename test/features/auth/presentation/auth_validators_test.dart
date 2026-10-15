import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/auth/presentation/validators/auth_validators.dart';

void main() {
  group('email', () {
    test('rechaza vacío y formato inválido', () {
      expect(AuthValidators.email(''), isNotNull);
      expect(AuthValidators.email('carlos@'), isNotNull);
      expect(AuthValidators.email('carlos elgolazo.com'), isNotNull);
    });

    test('acepta un correo válido con espacios alrededor', () {
      expect(AuthValidators.email(' carlos@elgolazo.com.co '), isNull);
    });
  });

  test('password exige un valor', () {
    expect(AuthValidators.password(''), isNotNull);
    expect(AuthValidators.password('secreto'), isNull);
  });
}
