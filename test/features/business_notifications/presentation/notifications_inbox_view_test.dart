import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/widgets/app_top_bar.dart';
import 'package:mi_cancha/core/widgets/notifications_bell_scope.dart';
import 'package:mi_cancha/features/business_notifications/domain/entities/app_notification.dart';
import 'package:mi_cancha/features/business_notifications/presentation/bloc/notifications_inbox_cubit.dart';
import 'package:mi_cancha/features/business_notifications/presentation/widgets/notifications_inbox_sheet.dart';
import 'package:mocktail/mocktail.dart';

import '../inbox_fixtures.dart';

class _MockCubit extends MockCubit<NotificationsInboxState>
    implements NotificationsInboxCubit {}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('campana', () {
    Future<void> pump(
      WidgetTester tester, {
      int unread = 0,
      VoidCallback? onOpen,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationsBellScope(
            unread: unread,
            onOpen: onOpen ?? () {},
            child: const AppTopBar(title: 'Pagos', icon: Icons.payments),
          ),
        ),
      ),
    );

    testWidgets('con no leídas lo anuncia y al tocarla abre la bandeja', (
      tester,
    ) async {
      var opened = false;
      await pump(tester, unread: 3, onOpen: () => opened = true);
      expect(
        find.bySemanticsLabel('Notificaciones, tienes nuevas'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Notificaciones'));
      expect(opened, isTrue);
    });

    testWidgets('sin no leídas no muestra el aviso', (tester) async {
      await pump(tester);
      expect(
        find.bySemanticsLabel('Notificaciones, tienes nuevas'),
        findsNothing,
      );
    });
  });

  group('bandeja', () {
    late _MockCubit cubit;
    setUp(() => cubit = _MockCubit());

    Future<void> pump(
      WidgetTester tester,
      NotificationsInboxState state,
    ) async {
      when(() => cubit.state).thenReturn(state);
      when(() => cubit.markAllRead()).thenAnswer((_) async {});
      when(() => cubit.loadMore()).thenAnswer((_) async {});
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<NotificationsInboxCubit>.value(
              value: cubit,
              child: const NotificationsInboxView(),
            ),
          ),
        ),
      );
    }

    testWidgets('lista las notificaciones y marca las no leídas', (
      tester,
    ) async {
      await pump(
        tester,
        NotificationsInboxState(
          status: InboxStatus.ready,
          items: [notification('a'), notification('b', unread: false)],
          unread: 1,
          page: 1,
        ),
      );
      expect(find.byType(NotificationTile), findsNWidgets(2));
      expect(find.byKey(const Key('inbox-unread-dot')), findsOneWidget);

      await tester.tap(find.byKey(const Key('inbox-read-all')));
      verify(() => cubit.markAllRead()).called(1);
    });

    testWidgets('al tocar una se marca como leída y muestra su detalle', (
      tester,
    ) async {
      final unread = notification('a');
      when(() => cubit.markRead(unread)).thenAnswer((_) async {});
      await pump(
        tester,
        NotificationsInboxState(
          status: InboxStatus.ready,
          items: [unread],
          unread: 1,
          page: 1,
        ),
      );
      await tester.tap(find.byType(NotificationTile));
      await tester.pumpAndSettle();

      verify(() => cubit.markRead(unread)).called(1);
      expect(find.byKey(const Key('notification-detail')), findsOneWidget);
      // El texto completo se ve en el detalle (además del listado).
      expect(find.text(unread.body), findsNWidgets(2));

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('notification-detail')), findsNothing);
      // La bandeja sigue abierta: no se navegó a otra pantalla.
      expect(find.byType(NotificationTile), findsOneWidget);
    });

    testWidgets('un aviso con imagen la muestra en el listado y el detalle', (
      tester,
    ) async {
      final withImage = notification(
        'img',
        unread: false,
        kind: NotificationKind.adminBroadcast,
        imageUrl: 'https://api.test/api/v1/images/notifications/i1',
      );
      when(() => cubit.markRead(withImage)).thenAnswer((_) async {});
      await pump(
        tester,
        NotificationsInboxState(
          status: InboxStatus.ready,
          items: [withImage, notification('sin', unread: false)],
          page: 1,
        ),
      );
      // Solo el aviso con imagen lleva miniatura.
      expect(find.byKey(const Key('inbox-thumbnail')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('img')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const Key('notification-detail-image')),
        findsOneWidget,
      );
    });

    testWidgets('sin no leídas el botón de marcar todas está deshabilitado', (
      tester,
    ) async {
      await pump(
        tester,
        NotificationsInboxState(
          status: InboxStatus.ready,
          items: [notification('b', unread: false)],
          page: 1,
        ),
      );
      final button = tester.widget<TextButton>(
        find.byKey(const Key('inbox-read-all')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('bandeja vacía', (tester) async {
      await pump(
        tester,
        const NotificationsInboxState(status: InboxStatus.ready),
      );
      expect(find.text('No tienes notificaciones.'), findsOneWidget);
    });
  });
}
