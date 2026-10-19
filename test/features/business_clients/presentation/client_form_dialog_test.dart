import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/client_profile.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_failure.dart';
import 'package:mi_cancha/features/business_clients/domain/entities/customer_payload.dart';
import 'package:mi_cancha/features/business_clients/domain/usecases/create_business_customer.dart';
import 'package:mi_cancha/features/business_clients/domain/usecases/update_business_customer.dart';
import 'package:mi_cancha/features/business_clients/presentation/widgets/client_form_dialog.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreateBusinessCustomer extends Mock
    implements CreateBusinessCustomer {}

class _MockUpdateBusinessCustomer extends Mock
    implements UpdateBusinessCustomer {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(
      const CustomerPayload(name: 'x', phone: '1', documentId: '2'),
    );
  });

  late _MockCreateBusinessCustomer createBusinessCustomer;
  late _MockUpdateBusinessCustomer updateBusinessCustomer;

  final sampleCreatedClient = ClientProfile(
    id: 'cli-new',
    name: 'Laura Gómez',
    phone: '3115550001',
    documentId: '1075111222',
    preferredSport: 'Pádel',
    tier: ClientTier.nuevo,
    totalBookings: 0,
    completedBookings: 0,
    totalSpentCop: 0,
    pendingDebtCop: 0,
    notes: 'Jugadora de fin de semana',
  );

  setUp(() {
    createBusinessCustomer = _MockCreateBusinessCustomer();
    updateBusinessCustomer = _MockUpdateBusinessCustomer();
  });

  Widget buildSubject({
    ClientProfile? initialClient,
    void Function(ClientProfile?)? onResult,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                final res = await showClientFormDialog(
                  context,
                  initialClient: initialClient,
                  createUseCase: createBusinessCustomer,
                  updateUseCase: updateBusinessCustomer,
                );
                onResult?.call(res);
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('validates required fields before submitting', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo Cliente'), findsOneWidget);

    await tester.tap(find.text('Crear Cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa el nombre (mínimo 2 letras).'), findsOneWidget);
    expect(
      find.text('Teléfono de 7 a 20 dígitos (puede llevar espacios, - o +).'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Cédula de 4 a 20 caracteres (letras, números, puntos o guiones).',
      ),
      findsOneWidget,
    );
  });

  testWidgets('submits new customer successfully and returns result', (
    tester,
  ) async {
    when(
      () => createBusinessCustomer(any()),
    ).thenAnswer((_) async => sampleCreatedClient);

    ClientProfile? returnedClient;
    await tester.pumpWidget(
      buildSubject(onResult: (res) => returnedClient = res),
    );
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ej. Laura Gómez'),
      'Laura Gómez',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ej. 311 555 0001'),
      '3115550001',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ej. 1.075.111.222'),
      '1075111222',
    );
    await tester.enterText(
      find.widgetWithText(
        TextFormField,
        'Ej. Juega martes por la noche, solicita petos...',
      ),
      'Jugadora de fin de semana',
    );

    await tester.tap(find.text('Crear Cliente'));
    await tester.pumpAndSettle();

    expect(returnedClient, isNotNull);
    expect(returnedClient?.id, 'cli-new');
    expect(returnedClient?.name, 'Laura Gómez');
    verify(() => createBusinessCustomer(any())).called(1);
  });

  testWidgets('displays conflict error banner when 409 conflict occurs', (
    tester,
  ) async {
    when(() => createBusinessCustomer(any())).thenThrow(
      const CustomerException(
        failure: CustomerFailure.conflict,
        message:
            'Ya existe un cliente registrado con este celular o documento.',
      ),
    );

    await tester.pumpWidget(buildSubject());
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ej. Laura Gómez'),
      'Laura Gómez',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ej. 311 555 0001'),
      '3115550001',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ej. 1.075.111.222'),
      '1075111222',
    );

    await tester.tap(find.text('Crear Cliente'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Ya existe un cliente registrado con este celular o documento.',
      ),
      findsOneWidget,
    );
    expect(find.text('Nuevo Cliente'), findsOneWidget); // modal remains open
  });
}
