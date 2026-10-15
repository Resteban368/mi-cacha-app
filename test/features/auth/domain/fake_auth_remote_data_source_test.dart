import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mi_cancha/features/auth/domain/entities/auth_method.dart';
import 'package:mi_cancha/features/auth/domain/entities/auth_user.dart';

void main() {
  test('simula latencia antes de devolver el usuario', () {
    fakeAsync((async) {
      AuthUser? result;
      const FakeAuthRemoteDataSource(
        latency: Duration(seconds: 2),
      ).signIn(AuthMethod.email).then((u) => result = u);

      async.elapse(const Duration(milliseconds: 1999));
      expect(result, isNull);
      async.elapse(const Duration(milliseconds: 1));
      expect(result, isNotNull);
    });
  });
}
