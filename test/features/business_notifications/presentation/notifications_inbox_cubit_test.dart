import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/core/utils/clock.dart';
import 'package:mi_cancha/features/business_notifications/domain/usecases/inbox_usecases.dart';
import 'package:mi_cancha/features/business_notifications/presentation/bloc/notifications_inbox_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../inbox_fixtures.dart';

class _MockGet extends Mock implements GetNotifications {}

class _MockUnread extends Mock implements GetUnreadNotificationsCount {}

class _MockRead extends Mock implements MarkNotificationRead {}

class _MockReadAll extends Mock implements MarkAllNotificationsRead {}

class _FixedClock extends Clock {
  const _FixedClock();

  @override
  DateTime now() => inboxNow;
}

void main() {
  setUpAll(() => registerFallbackValue(const NoParams()));

  late _MockGet getNotifications;
  late _MockUnread getUnread;
  late _MockRead markRead;
  late _MockReadAll markAllRead;

  setUp(() {
    getNotifications = _MockGet();
    getUnread = _MockUnread();
    markRead = _MockRead();
    markAllRead = _MockReadAll();
  });

  NotificationsInboxCubit build() => NotificationsInboxCubit(
    getNotifications: getNotifications,
    getUnreadCount: getUnread,
    markRead: markRead,
    markAllRead: markAllRead,
    clock: const _FixedClock(),
  );

  final ready = NotificationsInboxState(
    status: InboxStatus.ready,
    items: [notification('a'), notification('b', unread: false)],
    unread: 1,
    page: 1,
  );

  blocTest<NotificationsInboxCubit, NotificationsInboxState>(
    'el contador actualiza la insignia',
    setUp: () => when(() => getUnread(any())).thenAnswer((_) async => 4),
    build: build,
    act: (cubit) => cubit.refreshUnread(),
    expect: () => [const NotificationsInboxState(unread: 4)],
  );

  blocTest<NotificationsInboxCubit, NotificationsInboxState>(
    'si falla el contador no cambia nada',
    setUp: () => when(() => getUnread(any())).thenThrow(Exception()),
    build: build,
    act: (cubit) => cubit.refreshUnread(),
    expect: () => <NotificationsInboxState>[],
  );

  blocTest<NotificationsInboxCubit, NotificationsInboxState>(
    'carga la primera página',
    setUp: () => when(
      () => getNotifications(1),
    ).thenAnswer((_) async => page([notification('a')], total: 30, unread: 2)),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const NotificationsInboxState(status: InboxStatus.loading),
      NotificationsInboxState(
        status: InboxStatus.ready,
        items: [notification('a')],
        unread: 2,
        page: 1,
        hasMore: true,
      ),
    ],
  );

  blocTest<NotificationsInboxCubit, NotificationsInboxState>(
    'sin red y sin datos: error',
    setUp: () => when(() => getNotifications(1)).thenThrow(Exception()),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const NotificationsInboxState(status: InboxStatus.loading),
      const NotificationsInboxState(status: InboxStatus.failure),
    ],
  );

  blocTest<NotificationsInboxCubit, NotificationsInboxState>(
    'cargar más agrega la siguiente página',
    setUp: () => when(() => getNotifications(2)).thenAnswer(
      (_) async => page([notification('c')], page: 2, total: 3, unread: 1),
    ),
    build: build,
    seed: () => ready.copyWith(hasMore: true),
    act: (cubit) => cubit.loadMore(),
    expect: () => [
      ready.copyWith(hasMore: true, loadingMore: true),
      ready.copyWith(
        items: [...ready.items, notification('c')],
        page: 2,
        hasMore: false,
      ),
    ],
  );

  blocTest<NotificationsInboxCubit, NotificationsInboxState>(
    'sin más páginas no pide nada',
    build: build,
    seed: () => ready,
    act: (cubit) => cubit.loadMore(),
    expect: () => <NotificationsInboxState>[],
    verify: (_) => verifyNever(() => getNotifications(any())),
  );

  blocTest<NotificationsInboxCubit, NotificationsInboxState>(
    'marcar una como leída baja la insignia al instante',
    setUp: () => when(() => markRead('a')).thenAnswer((_) async {}),
    build: build,
    seed: () => ready,
    act: (cubit) => cubit.markRead(notification('a')),
    expect: () => [
      ready.copyWith(
        items: [
          notification('a').markedRead(inboxNow),
          notification('b', unread: false),
        ],
        unread: 0,
      ),
    ],
    verify: (_) => verify(() => markRead('a')).called(1),
  );

  blocTest<NotificationsInboxCubit, NotificationsInboxState>(
    'una ya leída no se vuelve a marcar',
    build: build,
    seed: () => ready,
    act: (cubit) => cubit.markRead(notification('b', unread: false)),
    expect: () => <NotificationsInboxState>[],
    verify: (_) => verifyNever(() => markRead(any())),
  );

  blocTest<NotificationsInboxCubit, NotificationsInboxState>(
    'marcar todas como leídas',
    setUp: () => when(() => markAllRead(any())).thenAnswer((_) async {}),
    build: build,
    seed: () => ready,
    act: (cubit) => cubit.markAllRead(),
    expect: () => [
      ready.copyWith(
        items: [
          notification('a').markedRead(inboxNow),
          notification('b', unread: false),
        ],
        unread: 0,
      ),
    ],
  );

  blocTest<NotificationsInboxCubit, NotificationsInboxState>(
    'si falla marcar todas, se vuelve a pedir el contador real',
    setUp: () {
      when(() => markAllRead(any())).thenThrow(Exception());
      when(() => getUnread(any())).thenAnswer((_) async => 1);
    },
    build: build,
    seed: () => ready,
    act: (cubit) => cubit.markAllRead(),
    expect: () => [
      ready.copyWith(
        items: [
          notification('a').markedRead(inboxNow),
          notification('b', unread: false),
        ],
        unread: 0,
      ),
      ready.copyWith(
        items: [
          notification('a').markedRead(inboxNow),
          notification('b', unread: false),
        ],
        unread: 1,
      ),
    ],
  );
}
