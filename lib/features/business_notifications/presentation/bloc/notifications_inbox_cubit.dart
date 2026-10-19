import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/inbox_usecases.dart';

enum InboxStatus { initial, loading, ready, failure }

final class NotificationsInboxState extends Equatable {
  const NotificationsInboxState({
    this.status = InboxStatus.initial,
    this.items = const [],
    this.unread = 0,
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
  });

  final InboxStatus status;
  final List<AppNotification> items;

  /// No leídas en total (insignia de la campana).
  final int unread;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  NotificationsInboxState copyWith({
    InboxStatus? status,
    List<AppNotification>? items,
    int? unread,
    int? page,
    bool? hasMore,
    bool? loadingMore,
  }) => NotificationsInboxState(
    status: status ?? this.status,
    items: items ?? this.items,
    unread: unread ?? this.unread,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
  );

  @override
  List<Object?> get props => [
    status,
    items,
    unread,
    page,
    hasMore,
    loadingMore,
  ];
}

/// Bandeja de notificaciones del negocio y la insignia de la campana.
class NotificationsInboxCubit extends Cubit<NotificationsInboxState> {
  NotificationsInboxCubit({
    required GetNotifications getNotifications,
    required GetUnreadNotificationsCount getUnreadCount,
    required MarkNotificationRead markRead,
    required MarkAllNotificationsRead markAllRead,
    Clock clock = const Clock(),
  }) : _getNotifications = getNotifications,
       _getUnreadCount = getUnreadCount,
       _markRead = markRead,
       _markAllRead = markAllRead,
       _clock = clock,
       super(const NotificationsInboxState());

  final GetNotifications _getNotifications;
  final GetUnreadNotificationsCount _getUnreadCount;
  final MarkNotificationRead _markRead;
  final MarkAllNotificationsRead _markAllRead;
  final Clock _clock;

  /// Solo el contador (barato): al abrir la app, cada cierto tiempo y cuando
  /// llega un push.
  Future<void> refreshUnread() async {
    try {
      final unread = await _getUnreadCount(const NoParams());
      if (!isClosed) emit(state.copyWith(unread: unread));
    } catch (_) {
      // La insignia no es crítica: se reintenta en el siguiente refresco.
    }
  }

  /// Primera página. Si ya hay datos, recarga sin ocultarlos.
  Future<void> load() async {
    if (state.items.isEmpty) emit(state.copyWith(status: InboxStatus.loading));
    try {
      final page = await _getNotifications(1);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: InboxStatus.ready,
          items: page.items,
          unread: page.unread,
          page: 1,
          hasMore: page.hasMore,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      if (state.items.isEmpty) {
        emit(state.copyWith(status: InboxStatus.failure));
      }
    }
  }

  /// Al llegar un aviso: contador y, si la bandeja ya se abrió, el listado.
  Future<void> refresh() =>
      state.status == InboxStatus.ready ? load() : refreshUnread();

  Future<void> loadMore() async {
    if (state.status != InboxStatus.ready ||
        !state.hasMore ||
        state.loadingMore) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _getNotifications(state.page + 1);
      if (isClosed) return;
      emit(
        state.copyWith(
          items: [...state.items, ...page.items],
          unread: page.unread,
          page: page.page,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (!isClosed) emit(state.copyWith(loadingMore: false));
    }
  }

  /// Marca como leída al instante; el servidor es idempotente.
  Future<void> markRead(AppNotification notification) async {
    if (!notification.isUnread) return;
    final now = _clock.now();
    emit(
      state.copyWith(
        items: [
          for (final n in state.items)
            n.id == notification.id ? n.markedRead(now) : n,
        ],
        unread: (state.unread - 1).clamp(0, state.unread),
      ),
    );
    try {
      await _markRead(notification.id);
    } catch (_) {
      // Si falló, el siguiente refresco trae el estado real.
    }
  }

  Future<void> markAllRead() async {
    if (state.unread == 0 && !state.items.any((n) => n.isUnread)) return;
    final now = _clock.now();
    emit(
      state.copyWith(
        items: [for (final n in state.items) n.markedRead(now)],
        unread: 0,
      ),
    );
    try {
      await _markAllRead(const NoParams());
    } catch (_) {
      await refreshUnread();
    }
  }
}
