import 'package:equatable/equatable.dart';

/// Tipo de notificación de la bandeja (fijo en la plataforma).
enum NotificationKind {
  newReservation('NEW_RESERVATION'),
  adminBroadcast('ADMIN_BROADCAST'),

  /// Tipo que la app aún no conoce (solo para mostrar).
  other(null);

  const NotificationKind(this.apiCode);

  final String? apiCode;

  static NotificationKind fromApi(String? code) =>
      values.firstWhere((kind) => kind.apiCode == code, orElse: () => other);
}

/// Una notificación de la bandeja del negocio.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.url,
    this.imageUrl,
    this.readAt,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;

  /// Ruta de la app que se abre al tocarla.
  final String? url;

  /// Imagen del aviso (URL pública), si tiene. Las reservas no traen.
  final String? imageUrl;

  /// `null` = sin leer.
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;

  AppNotification markedRead(DateTime at) => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    url: url,
    imageUrl: imageUrl,
    readAt: readAt ?? at,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    kind,
    title,
    body,
    url,
    imageUrl,
    readAt,
    createdAt,
  ];
}

/// Una página de la bandeja (de la más reciente a la más antigua).
class NotificationPage extends Equatable {
  const NotificationPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.unread,
  });

  static const defaultPageSize = 20;

  final List<AppNotification> items;
  final int total;
  final int page;
  final int pageSize;

  /// No leídas en total (para la insignia).
  final int unread;

  bool get hasMore => page * pageSize < total;

  @override
  List<Object?> get props => [items, total, page, pageSize, unread];
}
