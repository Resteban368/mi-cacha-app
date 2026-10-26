import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/client_filter.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/client_profile.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_metrics.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_overview.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_query.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customers_page_result.dart';
import 'package:mi_cancha/features/business_clients/presentation/bloc/business_clients_bloc.dart';
import 'package:mi_cancha/features/business_clients/presentation/bloc/business_clients_event.dart';
import 'package:mi_cancha/features/business_clients/presentation/bloc/business_clients_state.dart';
import 'package:mi_cancha/features/business_clients/presentation/pages/business_clients_page.dart';
import 'package:mi_cancha/features/business_clients/presentation/widgets/client_card_item.dart';
import 'package:mi_cancha/features/business_clients/presentation/widgets/clients_data_table.dart';
import 'package:mi_cancha/features/business_clients/presentation/widgets/clients_filter_bar.dart';
import 'package:mi_cancha/features/business_clients/presentation/widgets/clients_metric_cards.dart';
import 'package:mi_cancha/features/business_clients/presentation/widgets/clients_shimmer.dart';
import 'package:mocktail/mocktail.dart';

class _MockBusinessClientsBloc
    extends MockBloc<BusinessClientsEvent, BusinessClientsState>
    implements BusinessClientsBloc {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const BusinessClientsStarted());
    registerFallbackValue(const BusinessClientsSearchChanged(''));
    registerFallbackValue(
      const BusinessClientsSegmentChanged(ClientFilterType.all),
    );
  });

  late _MockBusinessClientsBloc bloc;

  final sampleClients = [
    ClientProfile(
      id: 'cli-001',
      name: 'Carlos Mendoza',
      phone: '+57 311 456 7890',
      documentId: '1020334881',
      tier: ClientTier.vip,
      preferredSport: 'FUTBOL',
      totalBookings: 24,
      completedBookings: 22,
      totalSpentCop: 1920000,
      pendingDebtCop: 0,
      notes: 'Capitán de equipo',
      metrics: CustomerMetrics(
        reservations: 24,
        attendancePct: 92,
        totalSpent: 1920000,
        balance: 0,
        level: 'VIP',
        favoriteSport: 'FUTBOL',
        lastVisitDate: DateTime.parse('2026-10-13T18:00:00Z'),
        lastVisitCourtName: 'Cancha Sintética 1',
      ),
    ),
    ClientProfile(
      id: 'cli-002',
      name: 'Andrés Gómez',
      phone: '+57 320 882 1144',
      documentId: '1018992341',
      tier: ClientTier.frecuente,
      preferredSport: 'PADEL',
      totalBookings: 10,
      completedBookings: 10,
      totalSpentCop: 800000,
      pendingDebtCop: 40000,
    ),
  ];

  const sampleOverview = CustomerOverview(
    totalCustomers: 2,
    newThisMonth: 1,
    newVsLastMonthPct: 14,
    loyalCustomers: 1,
    loyalPct: 50,
    totalReservations: 34,
    pendingBalance: 40000,
    currency: 'COP',
  );

  final sampleResult = CustomersPageResult(
    overview: sampleOverview,
    items: sampleClients,
    total: 2,
    page: 1,
    pageSize: 20,
  );

  final successState = BusinessClientsState(
    status: ClientsStatus.success,
    result: sampleResult,
    query: const CustomerQuery(),
  );

  setUp(() {
    bloc = _MockBusinessClientsBloc();
    whenListen(
      bloc,
      const Stream<BusinessClientsState>.empty(),
      initialState: successState,
    );
  });

  Widget buildSubject({
    Size size = const Size(1280, 900),
    BusinessClientsState? state,
  }) {
    if (state != null) {
      whenListen(
        bloc,
        const Stream<BusinessClientsState>.empty(),
        initialState: state,
      );
    }

    return MaterialApp(
      home: BlocProvider<BusinessClientsBloc>.value(
        value: bloc,
        child: MediaQuery(
          data: MediaQueryData(size: size),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: const Scaffold(body: BusinessClientsPage()),
          ),
        ),
      ),
    );
  }

  testWidgets('renders Web Desktop view with DataTable and Metric Cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject(size: const Size(1280, 900)));
    await tester.pumpAndSettle();

    expect(find.text('Clientes'), findsWidgets);
    expect(find.byType(ClientsMetricCards), findsOneWidget);
    expect(find.byType(ClientsFilterBar), findsOneWidget);
    expect(find.byType(ClientsDataTable), findsOneWidget);
    expect(find.text('TOTAL CLIENTES'), findsOneWidget);
    expect(find.text('Carlos Mendoza'), findsOneWidget);
    expect(find.text('Andrés Gómez'), findsOneWidget);
  });

  testWidgets('renders Mobile view with ClientCardItem cards', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject(size: const Size(400, 800)));
    await tester.pumpAndSettle();

    expect(find.byType(ClientsDataTable), findsNothing);
    expect(find.byType(ClientCardItem), findsNWidgets(2));
    expect(find.text('Carlos Mendoza'), findsOneWidget);
  });

  testWidgets('dispatches search event on query text entry', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject(size: const Size(1280, 900)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Andrés');
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(const BusinessClientsSearchChanged('Andrés')),
    ).called(1);
  });

  testWidgets('dispatches segment filter event on filter chip tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject(size: const Size(1280, 900)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Con saldo pendiente'));
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(
        const BusinessClientsSegmentChanged(ClientFilterType.withDebt),
      ),
    ).called(1);
  });

  testWidgets('tapping on client row opens client detail sheet / modal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject(size: const Size(1280, 900)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Carlos Mendoza'));
    await tester.pumpAndSettle();

    expect(find.text('MÉTRICAS Y ACTIVIDAD'), findsOneWidget);
    expect(find.text('PREFERENCIAS Y NOTAS'), findsOneWidget);
    expect(find.text('Ver Historial'), findsOneWidget);
    expect(find.text('Crear Reserva'), findsOneWidget);
  });

  testWidgets('tapping WhatsApp icon shows snackbar feedback', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject(size: const Size(1280, 900)));
    await tester.pumpAndSettle();

    final whatsappButton = find.byTooltip('Chatear por WhatsApp').first;
    await tester.tap(whatsappButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Iniciando chat con Carlos Mendoza'),
      findsOneWidget,
    );
  });

  testWidgets('renders failure state and triggers refresh on retry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const errorState = BusinessClientsState(
      status: ClientsStatus.failure,
      errorMessage: 'No se pudo conectar con el servidor',
    );

    await tester.pumpWidget(
      buildSubject(size: const Size(1280, 900), state: errorState),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudo conectar con el servidor'), findsWidgets);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(const BusinessClientsRefreshed())).called(1);
  });

  testWidgets(
    'renders ClientsShimmer when status is loading and clients list is empty',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const loadingState = BusinessClientsState(status: ClientsStatus.loading);

      await tester.pumpWidget(
        buildSubject(size: const Size(1280, 900), state: loadingState),
      );
      await tester.pump();

      expect(find.byType(ClientsShimmer), findsOneWidget);
      expect(find.byType(ClientsTableShimmer), findsOneWidget);
      expect(find.byType(ClientsDataTable), findsNothing);
    },
  );

  testWidgets(
    'renders ClientsCardListShimmer on mobile when status is loading',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const loadingState = BusinessClientsState(status: ClientsStatus.loading);

      await tester.pumpWidget(
        buildSubject(size: const Size(400, 800), state: loadingState),
      );
      await tester.pump();

      expect(find.byType(ClientsShimmer), findsOneWidget);
      expect(find.byType(ClientsCardListShimmer), findsOneWidget);
      expect(find.byType(ClientCardItem), findsNothing);
    },
  );

  group('scroll infinito y filtros fijos', () {
    final many = [
      for (var i = 0; i < 20; i++)
        ClientProfile(
          id: 'c$i',
          name: 'Cliente $i',
          phone: '311000000$i',
          documentId: '10000$i',
        ),
    ];
    BusinessClientsState pageOf({
      required int total,
      LoadMoreStatus loadMore = LoadMoreStatus.idle,
    }) => BusinessClientsState(
      status: ClientsStatus.success,
      result: CustomersPageResult(
        overview: sampleOverview,
        items: many,
        total: total,
        page: 1,
        pageSize: 20,
      ),
      items: many,
      loadMore: loadMore,
    );

    for (final size in const [Size(400, 800), Size(1280, 800)]) {
      testWidgets('al llegar al final pide más y los filtros quedan fijos '
          '(${size.width.toInt()} px)', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        await tester.pumpWidget(
          buildSubject(size: size, state: pageOf(total: 45)),
        );
        await tester.pump();

        // Desde abajo, sobre la lista (no sobre el buscador).
        await tester.dragFrom(
          Offset(size.width / 2, size.height - 40),
          const Offset(0, -12000),
        );
        await tester.pump();

        verify(
          () => bloc.add(const BusinessClientsNextPageRequested()),
        ).called(greaterThanOrEqualTo(1));
        // La búsqueda sigue a la vista, pegada arriba.
        final filters = tester.getRect(
          find.byKey(const Key('clients-pinned-filters')),
        );
        expect(filters.top, lessThan(120));
        expect(find.byType(ClientsFilterBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('sin más páginas avisa que ya están todos', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        buildSubject(size: const Size(400, 800), state: pageOf(total: 20)),
      );
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Ya ves todos los resultados (20 de 20)'),
        500,
        scrollable: find.byType(Scrollable).first,
      );

      expect(
        find.text('Ya ves todos los resultados (20 de 20)'),
        findsOneWidget,
      );
      verifyNever(() => bloc.add(const BusinessClientsNextPageRequested()));
    });

    testWidgets('cargando más muestra el indicador; si falla, reintentar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        buildSubject(
          size: const Size(400, 800),
          state: pageOf(total: 45, loadMore: LoadMoreStatus.failure),
        ),
      );
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const Key('clients-load-more-retry')),
        500,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.byKey(const Key('clients-load-more-retry')));
      verify(
        () => bloc.add(const BusinessClientsNextPageRequested()),
      ).called(1);
    });
  });
}
