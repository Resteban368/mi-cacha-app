import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/router/app_routes.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation_query.dart';
import 'package:mi_cancha/features/business_reservations/domain/usecases/booking_usecases.dart';
import 'package:mi_cancha/features/business_reservations/presentation/bloc/reservation_detail/reservation_detail_cubit.dart';
import 'package:mi_cancha/features/business_reservations/presentation/bloc/reservations_list/reservations_list_bloc.dart';
import 'package:mi_cancha/features/business_reservations/presentation/pages/business_reservations_list_page.dart';
import 'package:mi_cancha/features/business_reservations/presentation/widgets/reservation_list_tile.dart';
import 'package:mocktail/mocktail.dart';

import '../booking_fixtures.dart';
import '../reservation_fixtures.dart' as agenda;

class _MockBloc extends MockBloc<ReservationsListEvent, ReservationsListState>
    implements ReservationsListBloc {}

class _MockGet extends Mock implements GetReservation {}

class _MockCancel extends Mock implements CancelReservation {}

class _MockStatus extends Mock implements UpdateReservationStatus {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const ReservationsListMoreRequested());
  });

  late _MockBloc bloc;
  setUp(() => bloc = _MockBloc());

  List<Reservation> many(int n) => [
    for (var i = 0; i < n; i++)
      agenda.reservation(id: 'r$i', startHour: 8 + i % 12, name: 'Cliente $i'),
  ];

  ReservationsListState loaded({
    int count = 20,
    int total = 45,
    ReservationQuery query = const ReservationQuery(),
  }) => ReservationsListState(
    status: ReservationsListStatus.ready,
    items: many(count),
    total: total,
    page: 1,
    hasMore: count < total,
    query: query,
    courts: [court('c1')],
  );

  ReservationDetailCubit detailCubit() {
    final get = _MockGet();
    when(() => get(any())).thenThrow(Exception());
    return ReservationDetailCubit(
      getReservation: get,
      cancelReservation: _MockCancel(),
      updateStatus: _MockStatus(),
    );
  }

  Future<void> pump(
    WidgetTester tester,
    ReservationsListState state, {
    Size size = const Size(390, 844),
    String? customerName,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    whenListen(
      bloc,
      const Stream<ReservationsListState>.empty(),
      initialState: state,
    );
    final router = GoRouter(
      initialLocation: AppRoutes.businessAllReservations,
      routes: [
        GoRoute(
          path: AppRoutes.businessAllReservations,
          builder: (_, _) => Scaffold(
            body: BlocProvider<ReservationsListBloc>.value(
              value: bloc,
              child: BusinessReservationsListPage(
                createDetailCubit: detailCubit,
                customerName: customerName,
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.businessReservations,
          builder: (_, _) => const Scaffold(body: Text('agenda')),
        ),
        GoRoute(
          path: AppRoutes.businessNewReservation,
          builder: (_, _) => const Scaffold(body: Text('new')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
  }

  testWidgets('muestra el total y las reservas', (tester) async {
    await pump(tester, loaded());
    expect(find.text('Todas las reservas'), findsOneWidget);
    expect(find.text('45 reservas'), findsOneWidget);
    expect(find.byType(ReservationListTile), findsWidgets);
    expect(find.text('Cliente 0'), findsOneWidget);
  });

  testWidgets('al bajar pide la página siguiente', (tester) async {
    await pump(tester, loaded());
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2500));
    await tester.pump();
    verify(
      () => bloc.add(const ReservationsListMoreRequested()),
    ).called(greaterThanOrEqualTo(1));
  });

  testWidgets('escribir busca con espera', (tester) async {
    await pump(tester, loaded());
    await tester.enterText(
      find.byKey(const Key('reservations-search')),
      'laura',
    );
    verify(
      () => bloc.add(
        const ReservationsListQueryChanged(
          ReservationQuery(search: 'laura'),
          debounce: true,
        ),
      ),
    ).called(1);
  });

  testWidgets('filtrar por estado', (tester) async {
    await pump(tester, loaded());
    await tester.tap(find.byKey(const Key('filter-status')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelada').last);
    await tester.pumpAndSettle();
    verify(
      () => bloc.add(
        const ReservationsListQueryChanged(
          ReservationQuery(status: ReservationStatus.cancelled),
        ),
      ),
    ).called(1);
  });

  testWidgets('historial de un cliente muestra su filtro', (tester) async {
    await pump(
      tester,
      loaded(query: const ReservationQuery(customerId: 'cu1')),
      customerName: 'Laura Gómez',
    );
    expect(find.text('Cliente: Laura Gómez'), findsOneWidget);
    expect(find.text('Limpiar'), findsOneWidget);
  });

  testWidgets('sin resultados con filtros ofrece limpiarlos', (tester) async {
    await pump(
      tester,
      loaded(
        count: 0,
        total: 0,
        query: const ReservationQuery(status: ReservationStatus.noShow),
      ),
    );
    expect(find.text('No hay reservas con estos filtros'), findsOneWidget);
    await tester.tap(find.text('Limpiar filtros'));
    verify(
      () => bloc.add(const ReservationsListQueryChanged(ReservationQuery())),
    ).called(1);
  });

  testWidgets('al final de la lista lo indica', (tester) async {
    await pump(tester, loaded(count: 3, total: 3), size: const Size(390, 1400));
    expect(find.text('No hay más reservas'), findsOneWidget);
  });

  testWidgets('tocar una reserva abre su detalle', (tester) async {
    await pump(tester, loaded(count: 2, total: 2));
    await tester.tap(find.text('Cliente 0'));
    await tester.pumpAndSettle();
    expect(find.text('Cerrar'), findsOneWidget);
  });

  testWidgets('volver lleva a la agenda', (tester) async {
    await pump(tester, loaded());
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('agenda'), findsOneWidget);
  });

  for (final size in const [Size(320, 640), Size(1280, 900)]) {
    testWidgets('sin overflow en ${size.width}x${size.height}', (tester) async {
      await pump(tester, loaded(), size: size);
      expect(tester.takeException(), isNull);
    });
  }
}
