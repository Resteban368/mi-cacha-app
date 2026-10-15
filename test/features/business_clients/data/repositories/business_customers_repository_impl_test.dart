import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_clients/data/datasources/business_customers_data_source.dart';
import 'package:mi_cancha/features/business_clients/data/repositories/business_customers_repository_impl.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/client_profile.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_overview.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_payload.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_query.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customers_page_result.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements BusinessCustomersDataSource {}

void main() {
  late _MockDataSource dataSource;
  late BusinessCustomersRepositoryImpl repository;

  final sampleClient = ClientProfile(
    id: 'c1',
    name: 'Carlos Mendoza',
    phone: '+573114567890',
    documentId: '1020334881',
    preferredSport: Sport.futbol,
    tier: ClientTier.vip,
    totalBookings: 24,
    completedBookings: 22,
    totalSpentCop: 1920000,
    pendingDebtCop: 0,
    notes: 'Capitán de equipo',
  );

  const sampleOverview = CustomerOverview(
    totalCustomers: 1,
    newThisMonth: 0,
    loyalCustomers: 1,
    totalReservations: 24,
    pendingBalance: 0,
    currency: 'COP',
  );

  final sampleResult = CustomersPageResult(
    overview: sampleOverview,
    items: [sampleClient],
    total: 1,
    page: 1,
    pageSize: 20,
  );

  setUp(() {
    dataSource = _MockDataSource();
    repository = BusinessCustomersRepositoryImpl(dataSource);
  });

  group('BusinessCustomersRepositoryImpl', () {
    test('getCustomers delega al data source', () async {
      const query = CustomerQuery(page: 1);
      when(() => dataSource.getCustomers(query))
          .thenAnswer((_) async => sampleResult);

      final result = await repository.getCustomers(query);
      expect(result, equals(sampleResult));
      verify(() => dataSource.getCustomers(query)).called(1);
    });

    test('createCustomer delega al data source', () async {
      const payload = CustomerPayload(name: 'Carlos', phone: '311');
      when(() => dataSource.createCustomer(payload))
          .thenAnswer((_) async => sampleClient);

      final result = await repository.createCustomer(payload);
      expect(result, equals(sampleClient));
      verify(() => dataSource.createCustomer(payload)).called(1);
    });

    test('updateCustomer delega al data source', () async {
      const payload = CustomerPayload(name: 'Carlos Editado');
      when(() => dataSource.updateCustomer('c1', payload))
          .thenAnswer((_) async => sampleClient);

      final result = await repository.updateCustomer('c1', payload);
      expect(result, equals(sampleClient));
      verify(() => dataSource.updateCustomer('c1', payload)).called(1);
    });
  });
}
