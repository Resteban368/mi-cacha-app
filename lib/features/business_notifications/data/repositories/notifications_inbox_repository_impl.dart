import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_inbox_repository.dart';
import '../datasources/inbox_api_data_source.dart';

class NotificationsInboxRepositoryImpl implements NotificationsInboxRepository {
  const NotificationsInboxRepositoryImpl(this._api);

  final InboxApiDataSource _api;

  @override
  Future<NotificationPage> fetchPage({
    required int page,
    int pageSize = NotificationPage.defaultPageSize,
  }) => _api.fetchPage(page: page, pageSize: pageSize);

  @override
  Future<int> unreadCount() => _api.unreadCount();

  @override
  Future<void> markRead(String id) => _api.markRead(id);

  @override
  Future<void> markAllRead() => _api.markAllRead();
}
