import 'package:mi_cancha/features/business_notifications/domain/entities/app_notification.dart';

final inboxNow = DateTime(2026, 10, 19, 18, 30);

AppNotification notification(
  String id, {
  bool unread = true,
  NotificationKind kind = NotificationKind.newReservation,
  String? url = '/negocio/reservas',
}) => AppNotification(
  id: id,
  kind: kind,
  title: 'Nueva reserva',
  body: 'Pedro Pérez · Cancha 1 · mar 22 oct, 6:30 p. m.',
  url: url,
  readAt: unread ? null : inboxNow,
  createdAt: inboxNow.subtract(const Duration(minutes: 5)),
);

NotificationPage page(
  List<AppNotification> items, {
  int page = 1,
  int total = 0,
  int unread = 0,
}) => NotificationPage(
  items: items,
  total: total == 0 ? items.length : total,
  page: page,
  pageSize: NotificationPage.defaultPageSize,
  unread: unread,
);
