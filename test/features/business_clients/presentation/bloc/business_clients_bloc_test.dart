import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
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

class _MockGetBusinessCustomers extends Mock implements GetBusinessCustomers {}

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
    preferredSport: 'FUTBOL',
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
    registerFallbackValue(
      const CustomerPayload(name: 'x', phone: '1', documentId: '2'),
    );
  });

  setUp(() {
    getBusinessCustomers = _MockGetBusinessCustomers();
    createBusinessCustomer = _MockCreateBusinessCustomer();
    updateBusinessCustomer = _MockUpdateBusinessCustomer();

    when(
      () => getBusinessCustomers(any()),
    ).thenAnswer((_) async => sampleResult);
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
          status: ClientsStatus.success,
          result: sampleResult,
          items: [sampleClient],
        ),
      ],
    );

    blocTest<BusinessClientsBloc, BusinessClientsState>(
      'emits failure state on exception',
      setUp: () {
        when(() => getBusinessCustomers(any())).thenThrow(
          const CustomerException(
            failure: CustomerFailure.server,
            message: 'Error al cargar clientes',
          ),
        );
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
          status: ClientsStatus.success,
          result: sampleResult,
          items: [sampleClient],
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
        const BusinessClientsSegmentChanged(ClientFilterType.withDebt),
      ),
      expect: () => [
        const BusinessClientsState(
          query: CustomerQuery(segment: ClientFilterType.withDebt),
          status: ClientsStatus.loading,
        ),
        BusinessClientsState(
          query: const CustomerQuery(segment: ClientFilterType.withDebt),
          status: ClientsStatus.success,
          result: sampleResult,
          items: [sampleClient],
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
      act: (bloc) =>
          bloc.add(const BusinessClientsSortChanged(ClientSortBy.topSpenders)),
      expect: () => [
        const BusinessClientsState(
          query: CustomerQuery(sort: ClientSortBy.topSpenders),
          status: ClientsStatus.loading,
        ),
        BusinessClientsState(
          query: const CustomerQuery(sort: ClientSortBy.topSpenders),
          status: ClientsStatus.success,
          result: sampleResult,
          items: [sampleClient],
        ),
      ],
    );

    group('scroll infinito', () {
      ClientProfile client(String id) => ClientProfile(
        id: id,
        name: 'Cliente $id',
        phone: '3110000000',
        documentId: '1000$id',
      );
      CustomersPageResult page(int number, List<ClientProfile> items) =>
          CustomersPageResult(
            overview: sampleOverview,
            items: items,
            total: 3,
            page: number,
            pageSize: 2,
          );
      final firstPage = page(1, [client('a'), client('b')]);
      final loaded = BusinessClientsState(
        status: ClientsStatus.success,
        query: const CustomerQuery(pageSize: 2),
        result: firstPage,
        items: firstPage.items,
      );

      blocTest<BusinessClientsBloc, BusinessClientsState>(
        'agrega la página siguiente al final (sin repetidos)',
        setUp: () => when(
          () => getBusinessCustomers(any()),
        ).thenAnswer((_) async => page(2, [client('b'), client('c')])),
        build: () => BusinessClientsBloc(
          getBusinessCustomers: getBusinessCustomers,
          createBusinessCustomer: createBusinessCustomer,
          updateBusinessCustomer: updateBusinessCustomer,
        ),
        seed: () => loaded,
        act: (bloc) => bloc.add(const BusinessClientsNextPageRequested()),
        verify: (bloc) {
          expect(bloc.state.clients.map((c) => c.id), ['a', 'b', 'c']);
          expect(bloc.state.currentPage, 2);
          expect(bloc.state.hasNextPage, isFalse);
          expect(bloc.state.loadMore, LoadMoreStatus.idle);
          verify(
            () =>
                getBusinessCustomers(const CustomerQuery(page: 2, pageSize: 2)),
          ).called(1);
        },
      );

      blocTest<BusinessClientsBloc, BusinessClientsState>(
        'varios pedidos seguidos cargan una sola página',
        setUp: () =>
            when(() => getBusinessCustomers(any())).thenAnswer((_) async {
              await Future<void>.delayed(const Duration(milliseconds: 20));
              return page(2, [client('c')]);
            }),
        build: () => BusinessClientsBloc(
          getBusinessCustomers: getBusinessCustomers,
          createBusinessCustomer: createBusinessCustomer,
          updateBusinessCustomer: updateBusinessCustomer,
        ),
        seed: () => loaded,
        act: (bloc) => bloc
          ..add(const BusinessClientsNextPageRequested())
          ..add(const BusinessClientsNextPageRequested())
          ..add(const BusinessClientsNextPageRequested()),
        wait: const Duration(milliseconds: 60),
        verify: (bloc) {
          verify(() => getBusinessCustomers(any())).called(1);
          expect(bloc.state.clients.length, 3);
        },
      );

      blocTest<BusinessClientsBloc, BusinessClientsState>(
        'sin más páginas no pide nada',
        build: () => BusinessClientsBloc(
          getBusinessCustomers: getBusinessCustomers,
          createBusinessCustomer: createBusinessCustomer,
          updateBusinessCustomer: updateBusinessCustomer,
        ),
        seed: () => BusinessClientsState(
          status: ClientsStatus.success,
          result: sampleResult,
          items: [sampleClient],
        ),
        act: (bloc) => bloc.add(const BusinessClientsNextPageRequested()),
        expect: () => const <BusinessClientsState>[],
      );

      blocTest<BusinessClientsBloc, BusinessClientsState>(
        'error al cargar más: conserva la lista y permite reintentar',
        setUp: () =>
            when(() => getBusinessCustomers(any())).thenThrow(Exception('red')),
        build: () => BusinessClientsBloc(
          getBusinessCustomers: getBusinessCustomers,
          createBusinessCustomer: createBusinessCustomer,
          updateBusinessCustomer: updateBusinessCustomer,
        ),
        seed: () => loaded,
        act: (bloc) => bloc.add(const BusinessClientsNextPageRequested()),
        verify: (bloc) {
          expect(bloc.state.loadMore, LoadMoreStatus.failure);
          expect(bloc.state.clients.length, 2);
        },
      );

      blocTest<BusinessClientsBloc, BusinessClientsState>(
        'una búsqueda nueva descarta la página que llega tarde',
        setUp: () {
          when(
            () =>
                getBusinessCustomers(const CustomerQuery(page: 2, pageSize: 2)),
          ).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 30));
            return page(2, [client('c')]);
          });
          when(
            () => getBusinessCustomers(
              const CustomerQuery(pageSize: 2, search: 'zz'),
            ),
          ).thenAnswer((_) async => page(1, [client('z')]));
        },
        build: () => BusinessClientsBloc(
          getBusinessCustomers: getBusinessCustomers,
          createBusinessCustomer: createBusinessCustomer,
          updateBusinessCustomer: updateBusinessCustomer,
          searchDebounce: Duration.zero,
        ),
        seed: () => loaded,
        act: (bloc) async {
          bloc.add(const BusinessClientsNextPageRequested());
          await Future<void>.delayed(const Duration(milliseconds: 5));
          bloc.add(const BusinessClientsSearchChanged('zz'));
        },
        wait: const Duration(milliseconds: 80),
        verify: (bloc) {
          expect(bloc.state.query.search, 'zz');
          expect(bloc.state.clients.map((c) => c.id), ['z']);
        },
      );
    });
  });
}
