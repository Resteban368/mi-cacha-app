import '../entities/app_notification.dart';

abstract interface class NotificationsInboxRepository {
  Future<NotificationPage> fetchPage({required int page, int pageSize});

  Future<int> unreadCount();

  Future<void> markRead(String id);

  Future<void> markAllRead();
}
