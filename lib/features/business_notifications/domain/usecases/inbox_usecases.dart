import '../../../../core/usecase/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notifications_inbox_repository.dart';

class GetNotifications implements UseCase<NotificationPage, int> {
  const GetNotifications(this._repository);

  final NotificationsInboxRepository _repository;

  /// [page] empieza en 1.
  @override
  Future<NotificationPage> call(int page) => _repository.fetchPage(page: page);
}

class GetUnreadNotificationsCount implements UseCase<int, NoParams> {
  const GetUnreadNotificationsCount(this._repository);

  final NotificationsInboxRepository _repository;

  @override
  Future<int> call(NoParams params) => _repository.unreadCount();
}

class MarkNotificationRead implements UseCase<void, String> {
  const MarkNotificationRead(this._repository);

  final NotificationsInboxRepository _repository;

  @override
  Future<void> call(String id) => _repository.markRead(id);
}

class MarkAllNotificationsRead implements UseCase<void, NoParams> {
  const MarkAllNotificationsRead(this._repository);

  final NotificationsInboxRepository _repository;

  @override
  Future<void> call(NoParams params) => _repository.markAllRead();
}
