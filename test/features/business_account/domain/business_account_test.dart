import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/utils/formatters.dart';
import 'package:mi_cancha/features/business_account/data/datasources/business_account_data_source.dart';
import 'package:mi_cancha/features/business_account/domain/entities/business_account.dart';

void main() {
  group('AdminProfile.initials', () {
    AdminProfile admin(String name) =>
        AdminProfile(fullName: name, email: '', phone: '', roleLabel: '');

    test('toma la inicial de las dos primeras palabras', () {
      expect(admin('Carlos Rodríguez').initials, 'CR');
      expect(admin('  ana   maría  pérez ').initials, 'AM');
      expect(admin('Lucía').initials, 'L');
      expect(admin('').initials, '');
    });
  });

  group('Subscription', () {
    Subscription plan({required int limit, required int used}) => Subscription(
      planName: 'Plan',
      monthlyPrice: 1,
      since: DateTime(2026),
      nextPayment: DateTime(2026, 2),
      courtLimit: limit,
      courtsInUse: used,
      benefits: const [],
    );

    test('calcula uso y cupos libres', () {
      final p = plan(limit: 5, used: 3);
      expect(p.usage, 0.6);
      expect(p.freeCourtSlots, 2);
    });

    test('acota el uso cuando se excede el límite o no hay cupos', () {
      expect(plan(limit: 5, used: 7).usage, 1);
      expect(plan(limit: 5, used: 7).freeCourtSlots, 0);
      expect(plan(limit: 0, used: 0).usage, 0);
    });
  });

  test('mediumDate usa el mes abreviado con punto', () {
    expect(AppFormatters.mediumDate(DateTime(2026, 9, 15)), '15 sep. 2026');
    expect(AppFormatters.mediumDate(DateTime(2026, 10, 1)), '1 oct. 2026');
  });

  test('el fake devuelve la cuenta del diseño', () async {
    final source = FakeBusinessAccountDataSource(latency: Duration.zero);
    final account = await source.getAccount();
    expect(account.admin.fullName, 'Carlos Rodríguez');
    expect(account.subscription!.benefits, hasLength(4));
  });
}
