import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/features/business_notifications/domain/entities/push_message.dart';
import 'package:mi_cancha/features/business_notifications/presentation/bloc/notifications_inbox_cubit.dart';
import 'package:mi_cancha/features/business_notifications/presentation/widgets/notifications_inbox_host.dart';
import 'package:mocktail/mocktail.dart';

class _MockInbox extends MockCubit<NotificationsInboxState>
    implements NotificationsInboxCubit {}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('un aviso con la app abierta se muestra como mini aviso', (
    tester,
  ) async {
    final inbox = _MockInbox();
    when(() => inbox.state).thenReturn(const NotificationsInboxState());
    when(() => inbox.refresh()).thenAnswer((_) async {});
    when(() => inbox.refreshUnread()).thenAnswer((_) async {});
    when(() => inbox.load()).thenAnswer((_) async {});
    when(() => inbox.loadMore()).thenAnswer((_) async {});
    final messages = StreamController<PushMessage>.broadcast();
    addTearDown(messages.close);

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsInboxHost(
          createCubit: () => inbox,
          notificationsChanged: messages.stream,
          refreshInterval: null,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    messages.add(
      const PushMessage(
        type: 'NEW_RESERVATION',
        title: 'Nueva reserva',
        body: 'Pepe reservó Cancha 2 a las 6:00 p. m.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notification-toast')), findsOneWidget);
    expect(find.text('Nueva reserva'), findsOneWidget);
    expect(find.text('Pepe reservó Cancha 2 a las 6:00 p. m.'), findsOne);
    verify(() => inbox.refresh()).called(1);

    // "Ver" abre la bandeja.
    await tester.tap(find.byKey(const Key('notification-toast-open')));
    // La bandeja carga con un indicador animado: no se espera a que pare.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Notificaciones'), findsOneWidget);
  });
}
