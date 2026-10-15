import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/client_filter.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/client_profile.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_failure.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_overview.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_payload.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_query.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customers_page_result.dart';
import 'package:mi_cancha/features/business_clients/domain/usecases/create_business_customer.dart';
import 'package:mi_cancha/features/business_clients/domain/usecases/get_business_customers.dart';
import 'package:mi_cancha/features/business_clients/domain/usecases/update_business_customer.dart';
import 'package:mi_cancha/features/business_clients/presentation/bloc/business_clients_bloc.dart';
import 'package:mi_cancha/features/business_clients/presentation/bloc/business_clients_event.dart';
import 'package:mi_cancha/features/business_clients/presentation/bloc/business_clients_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetBusinessCustomers extends Mock
    implements GetBusinessCustomers {}

class _MockCreateBusinessCustomer extends Mock
    implements CreateBusinessCustomer {}

class _MockUpdateBusinessCustomer extends Mock
    implements UpdateBusinessCustomer {}

void main() {
  late _MockGetBusinessCustomers getBusinessCustomers;
  late _MockCreateBusinessCustomer createBusinessCustomer;
  late _MockUpdateBusinessCustomer updateBusinessCustomer;

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

  setUpAll(() {
    registerFallbackValue(const CustomerQuery());
    registerFallbackValue(const CustomerPayload(name: 'x'));
  });

  setUp(() {
    getBusinessCustomers = _MockGetBusinessCustomers();
    createBusinessCustomer = _MockCreateBusinessCustomer();
    updateBusinessCustomer = _MockUpdateBusinessCustomer();

    when(() => getBusinessCustomers(any()))
        .thenAnswer((_) async => sampleResult);
  });

  group('BusinessClientsBloc', () {
    blocTest<BusinessClientsBloc, BusinessClientsState>(
      'emits ready state with clients on BusinessClientsStarted',
      build: () => BusinessClientsBloc(
        getBusinessCustomers: getBusinessCustomers,
        createBusinessCustomer: createBusinessCustomer,
        updateBusinessCustomer: updateBusinessCustomer,
      ),
      act: (bloc) => bloc.add(const BusinessClientsStarted()),
      expect: () => [
        const BusinessClientsState(status: ClientsStatus.loading),
        BusinessClientsState(
          status: ClientsStatus.ready,
          overview: sampleOverview,
          clients: [sampleClient],
          totalClients: 1,
          currentPage: 1,
          pageSize: 20,
        ),
      ],
    );

    blocTest<BusinessClientsBloc, BusinessClientsState>(
      'emits failure state on exception',
      setUp: () {
        when(() => getBusinessCustomers(any()))
            .thenThrow(const CustomerFailure('Error al cargar clientes'));
      },
      build: () => BusinessClientsBloc(
        getBusinessCustomers: getBusinessCustomers,
        createBusinessCustomer: createBusinessCustomer,
        updateBusinessCustomer: updateBusinessCustomer,
      ),
      act: (bloc) => bloc.add(const BusinessClientsStarted()),
      expect: () => [
        const BusinessClientsState(status: ClientsStatus.loading),
        const BusinessClientsState(
          status: ClientsStatus.failure,
          errorMessage: 'Error al cargar clientes',
        ),
      ],
    );

    blocTest<BusinessClientsBloc, BusinessClientsState>(
      'debounces search changed and reloads with page 1',
      build: () => BusinessClientsBloc(
        getBusinessCustomers: getBusinessCustomers,
        createBusinessCustomer: createBusinessCustomer,
        updateBusinessCustomer: updateBusinessCustomer,
      ),
      act: (bloc) async {
        bloc.add(const BusinessClientsSearchChanged('Mendoza'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
      expect: () => [
        const BusinessClientsState(
          query: CustomerQuery(search: 'Mendoza'),
          status: ClientsStatus.loading,
        ),
        BusinessClientsState(
          query: const CustomerQuery(search: 'Mendoza'),
          status: ClientsStatus.ready,
          overview: sampleOverview,
          clients: [sampleClient],
          totalClients: 1,
          currentPage: 1,
          pageSize: 20,
        ),
      ],
    );

    blocTest<BusinessClientsBloc, BusinessClientsState>(
      'handles segment filter change',
      build: () => BusinessClientsBloc(
        getBusinessCustomers: getBusinessCustomers,
        createBusinessCustomer: createBusinessCustomer,
        updateBusinessCustomer: updateBusinessCustomer,
      ),
      act: (bloc) => bloc.add(
        const BusinessClientsSegmentChanged(ClientFilterSegment.withDebt),
      ),
      expect: () => [
        const BusinessClientsState(
          query: CustomerQuery(segment: ClientFilterSegment.withDebt),
          status: ClientsStatus.loading,
        ),
        BusinessClientsState(
          query: const CustomerQuery(segment: ClientFilterSegment.withDebt),
          status: ClientsStatus.ready,
          overview: sampleOverview,
          clients: [sampleClient],
          totalClients: 1,
          currentPage: 1,
          pageSize: 20,
        ),
      ],
    );

    blocTest<BusinessClientsBloc, BusinessClientsState>(
      'handles sorting change',
      build: () => BusinessClientsBloc(
        getBusinessCustomers: getBusinessCustomers,
        createBusinessCustomer: createBusinessCustomer,
        updateBusinessCustomer: updateBusinessCustomer,
      ),
      act: (bloc) => bloc.add(
        const BusinessClientsSortChanged(ClientFilterSort.topSpenders),
      ),
      expect: () => [
        const BusinessClientsState(
          query: CustomerQuery(sort: ClientFilterSort.topSpenders),
          status: ClientsStatus.loading,
        ),
        BusinessClientsState(
          query: const CustomerQuery(sort: ClientFilterSort.topSpenders),
          status: ClientsStatus.ready,
          overview: sampleOverview,
          clients: [sampleClient],
          totalClients: 1,
          currentPage: 1,
          pageSize: 20,
        ),
      ],
    );

    blocTest<BusinessClientsBloc, BusinessClientsState>(
      'handles page change',
      build: () => BusinessClientsBloc(
        getBusinessCustomers: getBusinessCustomers,
        createBusinessCustomer: createBusinessCustomer,
        updateBusinessCustomer: updateBusinessCustomer,
      ),
      act: (bloc) => bloc.add(const BusinessClientsPageChanged(2)),
      expect: () => [
        const BusinessClientsState(
          query: CustomerQuery(page: 2),
          currentPage: 2,
          status: ClientsStatus.loading,
        ),
        BusinessClientsState(
          query: const CustomerQuery(page: 2),
          status: ClientsStatus.ready,
          overview: sampleOverview,
          clients: [sampleClient],
          totalClients: 1,
          currentPage: 1,
          pageSize: 20,
        ),
      ],
    );
  });
}
