import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/app_notification.dart';

/// Bandeja del negocio (`/business/notifications`).
class InboxApiDataSource {
  const InboxApiDataSource(this._dio);

  final Dio _dio;

  static const _path = '/business/notifications';

  Future<NotificationPage> fetchPage({
    required int page,
    int pageSize = NotificationPage.defaultPageSize,
  }) async {
    final response = await apiCall(
      () => _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: {'page': page, 'pageSize': pageSize},
      ),
    );
    return pageFromJson(response.data!, page: page, pageSize: pageSize);
  }

  Future<int> unreadCount() async {
    final response = await apiCall(
      () => _dio.get<Map<String, dynamic>>('$_path/unread-count'),
    );
    return (response.data?['unread'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(String id) =>
      apiCall(() => _dio.post<void>('$_path/$id/read'));

  Future<void> markAllRead() =>
      apiCall(() => _dio.post<void>('$_path/read-all'));

  static NotificationPage pageFromJson(
    Map<String, dynamic> json, {
    required int page,
    required int pageSize,
  }) => NotificationPage(
    items: [
      for (final item in (json['items'] as List<dynamic>? ?? const []))
        notificationFromJson(item as Map<String, dynamic>),
    ],
    total: (json['total'] as num?)?.toInt() ?? 0,
    page: (json['page'] as num?)?.toInt() ?? page,
    pageSize: (json['pageSize'] as num?)?.toInt() ?? pageSize,
    unread: (json['unread'] as num?)?.toInt() ?? 0,
  );

  static AppNotification notificationFromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        kind: NotificationKind.fromApi(json['type'] as String?),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        url: json['url'] as String?,
        readAt: switch (json['readAt']) {
          final String at => DateTime.parse(at).toLocal(),
          _ => null,
        },
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );
}
