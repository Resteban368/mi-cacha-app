import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/client_profile.dart';
import 'package:mi_cancha/features/business_clients/presentation/pages/business_clients_page.dart';
import 'package:mi_cancha/features/business_clients/presentation/widgets/client_card_item.dart';
import 'package:mi_cancha/features/business_clients/presentation/widgets/clients_data_table.dart';
import 'package:mi_cancha/features/business_clients/presentation/widgets/clients_filter_bar.dart';
import 'package:mi_cancha/features/business_clients/presentation/widgets/clients_metric_cards.dart';

void main() {
  final sampleClients = [
    ClientProfile(
      id: 'cli-001',
      name: 'Carlos Mendoza',
      phone: '+57 311 456 7890',
      documentId: '1020334881',
      tier: ClientTier.vip,
      totalBookings: 20,
      completedBookings: 19,
      totalSpentCop: 1600000,
      pendingDebtCop: 0,
      notes: 'Capitán de equipo',
    ),
    ClientProfile(
      id: 'cli-002',
      name: 'Andrés Gómez',
      phone: '+57 320 882 1144',
      documentId: '1018992341',
      tier: ClientTier.frecuente,
      totalBookings: 10,
      completedBookings: 10,
      totalSpentCop: 800000,
      pendingDebtCop: 40000,
    ),
    ClientProfile(
      id: 'cli-003',
      name: 'David Silva',
      phone: '+57 312 334 5566',
      documentId: '1015678910',
      tier: ClientTier.nuevo,
      totalBookings: 1,
      completedBookings: 1,
      totalSpentCop: 80000,
      pendingDebtCop: 0,
    ),
  ];

  Widget buildSubject({
    Size size = const Size(1280, 900),
    List<ClientProfile>? clients,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Scaffold(
            body: BusinessClientsPage(
              initialClients: clients ?? sampleClients,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders Web Desktop view with DataTable and Metric Cards', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject(size: const Size(1280, 900)));
    await tester.pumpAndSettle();

    expect(find.text('Clientes'), findsWidgets);
    expect(find.byType(ClientsMetricCards), findsOneWidget);
    expect(find.byType(ClientsFilterBar), findsOneWidget);
    expect(find.byType(ClientsDataTable), findsOneWidget);
    expect(find.text('TOTAL CLIENTES'), findsOneWidget);
    expect(find.text('Carlos Mendoza'), findsOneWidget);
    expect(find.text('Andrés Gómez'), findsOneWidget);
  });

  testWidgets('renders Mobile view with ClientCardItem cards', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject(size: const Size(400, 800)));
    await tester.pumpAndSettle();

    expect(find.byType(ClientsDataTable), findsNothing);
    expect(find.byType(ClientCardItem), findsNWidgets(3));
    expect(find.text('Carlos Mendoza'), findsOneWidget);
  });

  testWidgets('filters clients by search query', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject(size: const Size(1280, 900)));
    await tester.pumpAndSettle();

    expect(find.text('Carlos Mendoza'), findsOneWidget);
    expect(find.text('Andrés Gómez'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Andrés');
    await tester.pumpAndSettle();

    expect(find.text('Carlos Mendoza'), findsNothing);
    expect(find.text('Andrés Gómez'), findsOneWidget);
  });

  testWidgets('filters clients by filter chip', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject(size: const Size(1280, 900)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Con saldo pendiente'));
    await tester.pumpAndSettle();

    expect(find.text('Carlos Mendoza'), findsNothing);
    expect(find.text('Andrés Gómez'), findsOneWidget);
  });

  testWidgets('tapping on client row opens client detail sheet / modal', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject(size: const Size(1280, 900)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Carlos Mendoza'));
    await tester.pumpAndSettle();

    expect(find.text('MÉTRICAS Y ACTIVIDAD'), findsOneWidget);
    expect(find.text('PREFERENCIAS Y NOTAS'), findsOneWidget);
    expect(find.text('Ver Historial'), findsOneWidget);
    expect(find.text('Crear Reserva'), findsOneWidget);
  });

  testWidgets('opens new client dialog and submits new player', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject(size: const Size(1280, 900)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nuevo Cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo Cliente'), findsWidgets);

    // Enter valid client details
    await tester.enterText(
      find.widgetWithText(TextField, 'Ej. Laura Gómez'),
      'Mariana Paz',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Ej. 311 555 0001'),
      '3101234567',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Ej. 1.075.111.222'),
      '1098765432',
    );

    await tester.tap(find.text('Crear Cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Mariana Paz'), findsOneWidget);
  });

  testWidgets('tapping WhatsApp icon shows snackbar feedback', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildSubject(size: const Size(1280, 900)));
    await tester.pumpAndSettle();

    final whatsappButton = find.byTooltip('Chatear por WhatsApp').first;
    await tester.tap(whatsappButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Iniciando chat con Carlos Mendoza'), findsOneWidget);
  });
}
