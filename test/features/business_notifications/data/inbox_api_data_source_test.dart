import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_notifications/data/datasources/inbox_api_data_source.dart';
import 'package:mi_cancha/features/business_notifications/domain/entities/app_notification.dart';

void main() {
  test('lee la página de la bandeja tal como la envía el backend', () {
    final page = InboxApiDataSource.pageFromJson(
      {
        'items': [
          {
            'id': 'n1',
            'type': 'NEW_RESERVATION',
            'title': 'Nueva reserva',
            'body': 'Pedro Pérez · Cancha 1 · mar 22 oct, 6:30 p. m.',
            'url': '/negocio/reservas',
            'data': {'reservationId': 'r1'},
            'readAt': null,
            'createdAt': '2026-10-19T18:22:02.432Z',
          },
          {
            'id': 'n2',
            'type': 'ADMIN_BROADCAST',
            'title': 'Mantenimiento',
            'body': 'El domingo de 2 a 4 a. m.',
            'url': null,
            'imageUrl': 'https://api.test/api/v1/images/notifications/i1',
            'data': null,
            'readAt': '2026-10-19T19:00:00.000Z',
            'createdAt': '2026-10-18T10:00:00.000Z',
          },
          {
            'id': 'n3',
            'type': 'ALGO_NUEVO',
            'title': 'x',
            'body': 'y',
            'createdAt': '2026-10-17T10:00:00.000Z',
          },
        ],
        'total': 45,
        'page': 1,
        'pageSize': 20,
        'unread': 3,
      },
      page: 1,
      pageSize: 20,
    );

    expect(page.items, hasLength(3));
    expect(page.unread, 3);
    expect(page.hasMore, isTrue);
    final [first, second, third] = page.items;
    expect(first.kind, NotificationKind.newReservation);
    expect(first.isUnread, isTrue);
    expect(first.url, '/negocio/reservas');
    expect(first.createdAt.isUtc, isFalse);
    expect(second.kind, NotificationKind.adminBroadcast);
    expect(second.isUnread, isFalse);
    expect(second.url, isNull);
    expect(second.imageUrl, 'https://api.test/api/v1/images/notifications/i1');
    expect(first.imageUrl, isNull);
    expect(third.kind, NotificationKind.other);
  });
}
