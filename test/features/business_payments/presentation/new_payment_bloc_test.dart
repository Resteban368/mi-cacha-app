import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/client_filter.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/client_profile.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_overview.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_query.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customers_page_result.dart';
import 'package:mi_cancha/features/business_clients/domain/usecases/get_business_customers.dart';
import 'package:mi_cancha/features/business_payments/domain/entities/new_payment.dart';
import 'package:mi_cancha/features/business_payments/domain/entities/payment.dart';
import 'package:mi_cancha/features/business_payments/domain/usecases/create_payment.dart';
import 'package:mi_cancha/features/business_payments/presentation/bloc/new_payment/new_payment_bloc.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/customer.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation_query.dart';
import 'package:mi_cancha/features/business_reservations/domain/usecases/booking_usecases.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreatePayment extends Mock implements CreatePayment {}

class _MockGetCustomers extends Mock implements GetBusinessCustomers {}

class _MockListReservations extends Mock implements ListReservations {}

void main() {
  late _MockCreatePayment createPayment;
  late _MockGetCustomers getCustomers;
  late _MockListReservations listReservations;

  const sampleCustomer = Customer(
    id: 'cust-1',
    name: 'Carlos Ruiz',
    phone: '3001234567',
    documentId: '10102020',
  );

  final sampleReservation = Reservation(
    id: 'res-1',
    courtName: 'Cancha Sintética 1',
    sport: Sport.futbol,
    start: DateTime(2026, 10, 15, 18),
    end: DateTime(2026, 10, 15, 19),
    customerName: 'Carlos Ruiz',
    phone: '3001234567',
    totalPrice: 80000,
    amountPaid: 30000,
    status: ReservationStatus.confirmed,
    customer: sampleCustomer,
  );

  ClientProfile profile(String id, String name) => ClientProfile(
    id: id,
    name: name,
    phone: '3001234567',
    documentId: '10102020',
  );

  CustomersPageResult page(
    List<ClientProfile> items, {
    int page = 1,
    int total = 1,
  }) => CustomersPageResult(
    overview: const CustomerOverview(),
    items: items,
    total: total,
    page: page,
    pageSize: 20,
  );

  CustomerQuery query({int page = 1, String search = ''}) =>
      CustomerQuery(page: page, search: search, sort: ClientSortBy.recent);

  const newPayment = NewPayment(
    customerName: 'Carlos Ruiz',
    amount: 50000,
    method: PaymentMethod.efectivo,
    concept: PaymentConcept.saldo,
    customerId: 'cust-1',
    reservationId: 'res-1',
  );

  final paymentResult = Payment(
    id: 'pay-1',
    customerName: 'Carlos Ruiz',
    amount: 50000,
    method: PaymentMethod.efectivo,
    concept: PaymentConcept.saldo,
    status: PaymentStatus.approved,
    receivedAt: DateTime(2026, 10, 15, 12),
  );

  setUpAll(() {
    registerFallbackValue(newPayment);
    registerFallbackValue((query: const ReservationQuery(), page: 1));
    registerFallbackValue(const CustomerQuery());
  });

  setUp(() {
    createPayment = _MockCreatePayment();
    getCustomers = _MockGetCustomers();
    listReservations = _MockListReservations();
  });

  NewPaymentBloc buildBloc() => NewPaymentBloc(
    createPayment: createPayment,
    getBusinessCustomers: getCustomers,
    listReservations: listReservations,
    searchDebounce: Duration.zero,
  );

  group('NewPaymentBloc', () {
    test('initial state has default values', () {
      final bloc = buildBloc();
      expect(bloc.state.status, NewPaymentStatus.initial);
      expect(bloc.state.targetMode, PaymentTargetMode.customer);
      expect(bloc.state.customerSearchStatus, EntitySearchStatus.idle);
      expect(bloc.state.customerResults, isEmpty);
      expect(bloc.state.selectedCustomer, isNull);
      expect(bloc.state.selectedReservation, isNull);
    });

    blocTest<NewPaymentBloc, NewPaymentState>(
      'NewPaymentStarted loads initial customers and reservations',
      setUp: () {
        when(
          () => getCustomers(any()),
        ).thenAnswer((_) async => page([profile('cust-1', 'Carlos Ruiz')]));
        when(() => listReservations(any())).thenAnswer(
          (_) async => ReservationPage(
            items: [sampleReservation],
            total: 1,
            page: 1,
            pageSize: 20,
          ),
        );
      },
      build: buildBloc,
      act: (b) => b.add(const NewPaymentStarted()),
      expect: () => [
        const NewPaymentState(
          customerSearchStatus: EntitySearchStatus.loading,
          reservationSearchStatus: EntitySearchStatus.loading,
        ),
        NewPaymentState(
          customerResults: const [sampleCustomer],
          customerPage: 1,
          customerSearchStatus: EntitySearchStatus.ready,
          reservationResults: [sampleReservation],
          reservationSearchStatus: EntitySearchStatus.ready,
        ),
      ],
    );

    blocTest<NewPaymentBloc, NewPaymentState>(
      'NewPaymentTargetModeChanged switches mode',
      build: buildBloc,
      act: (b) => b.add(
        const NewPaymentTargetModeChanged(PaymentTargetMode.reservation),
      ),
      expect: () => [
        const NewPaymentState(targetMode: PaymentTargetMode.reservation),
      ],
    );

    blocTest<NewPaymentBloc, NewPaymentState>(
      'NewPaymentCustomerSearchChanged searches customers',
      setUp: () {
        when(
          () => getCustomers(query(search: 'Carlos')),
        ).thenAnswer((_) async => page([profile('cust-1', 'Carlos Ruiz')]));
      },
      build: buildBloc,
      act: (b) => b.add(const NewPaymentCustomerSearchChanged('Carlos')),
      expect: () => [
        const NewPaymentState(customerSearchStatus: EntitySearchStatus.loading),
        const NewPaymentState(
          customerSearchStatus: EntitySearchStatus.ready,
          customerResults: [sampleCustomer],
          customerPage: 1,
        ),
      ],
    );

    blocTest<NewPaymentBloc, NewPaymentState>(
      'NewPaymentCustomerSelected fetches customer reservations',
      setUp: () {
        when(() => listReservations(any())).thenAnswer(
          (_) async => ReservationPage(
            items: [sampleReservation],
            total: 1,
            page: 1,
            pageSize: 20,
          ),
        );
      },
      build: buildBloc,
      act: (b) => b.add(const NewPaymentCustomerSelected(sampleCustomer)),
      expect: () => [
        const NewPaymentState(
          selectedCustomer: sampleCustomer,
          customerReservationsStatus: EntitySearchStatus.loading,
        ),
        NewPaymentState(
          selectedCustomer: sampleCustomer,
          customerReservations: [sampleReservation],
          customerReservationsStatus: EntitySearchStatus.ready,
        ),
      ],
    );

    blocTest<NewPaymentBloc, NewPaymentState>(
      'NewPaymentReservationSelected links reservation and customer',
      build: buildBloc,
      act: (b) => b.add(NewPaymentReservationSelected(sampleReservation)),
      expect: () => [
        NewPaymentState(
          selectedReservation: sampleReservation,
          selectedCustomer: sampleCustomer,
        ),
      ],
    );

    blocTest<NewPaymentBloc, NewPaymentState>(
      'NewPaymentSubmitted emits success on successful createPayment',
      setUp: () {
        when(() => createPayment(any())).thenAnswer((_) async => paymentResult);
      },
      build: buildBloc,
      act: (b) => b.add(const NewPaymentSubmitted(newPayment)),
      expect: () => [
        const NewPaymentState(status: NewPaymentStatus.submitting),
        NewPaymentState(
          status: NewPaymentStatus.success,
          created: paymentResult,
        ),
      ],
    );

    blocTest<NewPaymentBloc, NewPaymentState>(
      'NewPaymentSubmitted emits failure when createPayment throws',
      setUp: () {
        when(() => createPayment(any())).thenThrow(Exception('API error'));
      },
      build: buildBloc,
      act: (b) => b.add(const NewPaymentSubmitted(newPayment)),
      expect: () => [
        const NewPaymentState(status: NewPaymentStatus.submitting),
        const NewPaymentState(status: NewPaymentStatus.failure),
      ],
    );

    group('clientes con scroll infinito', () {
      final first = [for (var i = 0; i < 20; i++) profile('c$i', 'Cliente $i')];
      NewPaymentState loaded() => NewPaymentState(
        customerSearchStatus: EntitySearchStatus.ready,
        customerResults: [
          for (final c in first)
            Customer(
              id: c.id,
              name: c.name,
              phone: c.phone,
              documentId: c.documentId,
            ),
        ],
        customerPage: 1,
        customerHasMore: true,
      );

      blocTest<NewPaymentBloc, NewPaymentState>(
        'agrega la página siguiente (sin repetidos) y sabe cuándo termina',
        setUp: () => when(() => getCustomers(query(page: 2))).thenAnswer(
          (_) async => page(
            [profile('c19', 'Cliente 19'), profile('c20', 'Cliente 20')],
            page: 2,
            total: 21,
          ),
        ),
        build: buildBloc,
        seed: loaded,
        act: (b) => b.add(const NewPaymentCustomersNextPage()),
        verify: (b) {
          expect(b.state.customerResults.length, 21);
          expect(b.state.customerResults.last.id, 'c20');
          expect(b.state.customerPage, 2);
          expect(b.state.customerHasMore, isFalse);
          expect(b.state.customerLoadMoreStatus, EntitySearchStatus.idle);
        },
      );

      blocTest<NewPaymentBloc, NewPaymentState>(
        'varios pedidos seguidos cargan una sola página',
        setUp: () => when(() => getCustomers(any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return page([profile('c20', 'Cliente 20')], page: 2, total: 60);
        }),
        build: buildBloc,
        seed: loaded,
        act: (b) => b
          ..add(const NewPaymentCustomersNextPage())
          ..add(const NewPaymentCustomersNextPage())
          ..add(const NewPaymentCustomersNextPage()),
        wait: const Duration(milliseconds: 60),
        verify: (_) => verify(() => getCustomers(any())).called(1),
      );

      blocTest<NewPaymentBloc, NewPaymentState>(
        'si falla, conserva la lista y permite reintentar',
        setUp: () =>
            when(() => getCustomers(any())).thenThrow(Exception('red')),
        build: buildBloc,
        seed: loaded,
        act: (b) => b.add(const NewPaymentCustomersNextPage()),
        verify: (b) {
          expect(b.state.customerLoadMoreStatus, EntitySearchStatus.failure);
          expect(b.state.customerResults.length, 20);
        },
      );

      blocTest<NewPaymentBloc, NewPaymentState>(
        'una búsqueda nueva descarta la página que llega tarde',
        setUp: () {
          when(() => getCustomers(query(page: 2))).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 30));
            return page([profile('late', 'Tarde')], page: 2, total: 40);
          });
          when(
            () => getCustomers(query(search: 'zz')),
          ).thenAnswer((_) async => page([profile('z', 'Zoila')]));
        },
        build: buildBloc,
        seed: loaded,
        act: (b) async {
          b.add(const NewPaymentCustomersNextPage());
          await Future<void>.delayed(const Duration(milliseconds: 5));
          b.add(const NewPaymentCustomerSearchChanged('zz'));
        },
        wait: const Duration(milliseconds: 80),
        verify: (b) => expect(b.state.customerResults.map((c) => c.id), ['z']),
      );
    });
  });
}
