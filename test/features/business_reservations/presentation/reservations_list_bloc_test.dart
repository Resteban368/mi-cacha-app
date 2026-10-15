import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/business_courts/domain/usecases/get_courts.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation_query.dart';
import 'package:mi_cancha/features/business_reservations/domain/usecases/booking_usecases.dart';
import 'package:mi_cancha/features/business_reservations/presentation/bloc/reservations_list/reservations_list_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../booking_fixtures.dart';
import '../reservation_fixtures.dart' as agenda;

class _MockList extends Mock implements ListReservations {}

class _MockGetCourts extends Mock implements GetCourts {}

/// Página [page] de [total] reservas de 20 en 20.
ReservationPage pageOf(int page, {int total = 45}) {
  final count = (total - (page - 1) * 20).clamp(0, 20);
  return ReservationPage(
    items: [
      for (var i = 0; i < count; i++)
        agenda.reservation(id: 'p$page-$i', startHour: 10),
    ],
    total: total,
    page: page,
    pageSize: 20,
  );
}

void main() {
  late _MockList list;
  late _MockGetCourts getCourts;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue((query: const ReservationQuery(), page: 1));
  });

  setUp(() {
    list = _MockList();
    getCourts = _MockGetCourts();
    when(() => getCourts(any())).thenAnswer((_) async => [court('c1')]);
    when(() => list(any())).thenAnswer((invocation) async {
      final params =
          invocation.positionalArguments.single as ListReservationsParams;
      return pageOf(params.page);
    });
  });

  ReservationsListBloc build({Duration debounce = Duration.zero}) =>
      ReservationsListBloc(
        listReservations: list,
        getCourts: getCourts,
        searchDebounce: debounce,
      );

  blocTest<ReservationsListBloc, ReservationsListState>(
    'carga la primera página y las canchas',
    build: build,
    act: (bloc) => bloc.add(const ReservationsListStarted()),
    verify: (bloc) {
      final s = bloc.state;
      expect(s.status, ReservationsListStatus.ready);
      expect(s.items, hasLength(20));
      expect(s.total, 45);
      expect(s.hasMore, isTrue);
      expect(s.courts.single.id, 'c1');
    },
  );

  blocTest<ReservationsListBloc, ReservationsListState>(
    'cargar más agrega páginas hasta el final',
    build: build,
    act: (bloc) async {
      bloc.add(const ReservationsListStarted());
      await bloc.stream.firstWhere((s) => s.page == 1);
      bloc.add(const ReservationsListMoreRequested());
      await bloc.stream.firstWhere((s) => s.page == 2);
      bloc.add(const ReservationsListMoreRequested());
      await bloc.stream.firstWhere((s) => s.page == 3);
      // Ya no hay más: no pide otra página.
      bloc.add(const ReservationsListMoreRequested());
    },
    verify: (bloc) {
      expect(bloc.state.items, hasLength(45));
      expect(bloc.state.hasMore, isFalse);
      verify(() => list(any())).called(3);
    },
  );

  blocTest<ReservationsListBloc, ReservationsListState>(
    'buscar mientras se escribe: gana la última',
    build: () => build(debounce: const Duration(milliseconds: 20)),
    seed: () => const ReservationsListState(
      status: ReservationsListStatus.ready,
      page: 1,
    ),
    act: (bloc) => bloc
      ..add(
        const ReservationsListQueryChanged(
          ReservationQuery(search: 'la'),
          debounce: true,
        ),
      )
      ..add(
        const ReservationsListQueryChanged(
          ReservationQuery(search: 'laura'),
          debounce: true,
        ),
      ),
    wait: const Duration(milliseconds: 80),
    verify: (bloc) {
      final searched = verify(
        () => list(captureAny()),
      ).captured.map((p) => (p as ListReservationsParams).query.search);
      expect(searched, ['laura']);
      expect(bloc.state.query.search, 'laura');
    },
  );

  test(
    'una página que llega después de cambiar el filtro se descarta',
    () async {
      final slowPage = Completer<ReservationPage>();
      when(() => list(any())).thenAnswer((invocation) {
        final params =
            invocation.positionalArguments.single as ListReservationsParams;
        if (params.page == 2) return slowPage.future;
        return Future.value(
          params.query.status == ReservationStatus.cancelled
              ? pageOf(1, total: 3)
              : pageOf(1),
        );
      });
      final bloc = build()..add(const ReservationsListStarted());
      await bloc.stream.firstWhere((s) => s.page == 1);

      bloc.add(const ReservationsListMoreRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const ReservationsListQueryChanged(
          ReservationQuery(status: ReservationStatus.cancelled),
        ),
      );
      await bloc.stream.firstWhere((s) => s.total == 3);
      // Llega tarde la página 2 de la búsqueda anterior.
      slowPage.complete(pageOf(2));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state.items, hasLength(3));
      expect(bloc.state.query.status, ReservationStatus.cancelled);
      await bloc.close();
    },
  );

  blocTest<ReservationsListBloc, ReservationsListState>(
    'error al cargar más permite reintentar',
    build: build,
    seed: () => ReservationsListState(
      status: ReservationsListStatus.ready,
      items: pageOf(1).items,
      total: 45,
      page: 1,
      hasMore: true,
    ),
    setUp: () => when(() => list(any())).thenThrow(Exception()),
    act: (bloc) => bloc.add(const ReservationsListMoreRequested()),
    verify: (bloc) {
      expect(bloc.state.loadMoreFailed, isTrue);
      expect(bloc.state.items, hasLength(20));
    },
  );

  test('recargar completa el indicador aunque nada cambie', () async {
    final bloc = build()..add(const ReservationsListStarted());
    await bloc.stream.firstWhere((s) => s.page == 1);
    final done = Completer<void>();
    bloc.add(ReservationsListRefreshed(done: done));
    await expectLater(done.future, completes);
    await bloc.close();
  });
}
