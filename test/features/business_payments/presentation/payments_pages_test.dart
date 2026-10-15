import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/router/app_routes.dart';
import 'package:mi_cancha/core/utils/clock.dart';
import 'package:mi_cancha/features/business_payments/domain/entities/new_payment.dart';
import 'package:mi_cancha/features/business_payments/domain/entities/payment.dart';
import 'package:mi_cancha/features/business_payments/presentation/bloc/new_payment/new_payment_bloc.dart';
import 'package:mi_cancha/features/business_payments/presentation/bloc/payments/payments_bloc.dart';
import 'package:mi_cancha/features/business_payments/presentation/pages/new_payment_page.dart';
import 'package:mi_cancha/features/business_payments/presentation/pages/payments_page.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mi_cancha/features/business_payments/presentation/widgets/payment_card.dart';
import 'package:mi_cancha/features/business_payments/presentation/widgets/payments_tabs.dart';
import '../payment_fixtures.dart';

class _MockPaymentsBloc extends MockBloc<PaymentsEvent, PaymentsState>
    implements PaymentsBloc {}

class _MockNewPaymentBloc extends MockBloc<NewPaymentEvent, NewPaymentState>
    implements NewPaymentBloc {}

class _FixedClock extends Clock {
  const _FixedClock();

  @override
  DateTime now() => now_;
}

final now_ = now;

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const PaymentsRequested());
    registerFallbackValue(
      const NewPaymentSubmitted(
        NewPayment(
          customerName: '',
          amount: 0,
          method: PaymentMethod.efectivo,
          concept: PaymentConcept.total,
        ),
      ),
    );
  });

  void setSize(WidgetTester tester, [Size size = const Size(390, 1400)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('PaymentsPage', () {
    late _MockPaymentsBloc bloc;
    setUp(() => bloc = _MockPaymentsBloc());

    Future<void> pump(
      WidgetTester tester,
      PaymentsState state, {
      Size size = const Size(390, 1400),
    }) async {
      setSize(tester, size);
      when(() => bloc.state).thenReturn(state);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<PaymentsBloc>.value(
              value: bloc,
              child: const PaymentsPage(clock: _FixedClock()),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    PaymentsState loaded({PaymentStatus tab = PaymentStatus.pending}) =>
        PaymentsState(
          status: PaymentsStatus.success,
          payments: samplePayments,
          tab: tab,
        );

    testWidgets('muestra pendientes con resumen y acciones', (tester) async {
      await pump(tester, loaded());

      expect(find.text('Pagos'), findsOneWidget);
      expect(find.text('2 pagos por validar'), findsOneWidget);
      expect(find.text(r'$110.000'), findsOneWidget);
      expect(find.text('Valentina Dussán'), findsOneWidget);
      expect(find.text('Ref. Ma'), findsOneWidget);
      expect(find.text('hace 5 min'), findsNWidgets(2));
      expect(find.text('Aprobar'), findsNWidgets(2));
      expect(find.text('Rechazar'), findsNWidgets(2));
      expect(find.byTooltip('Nuevo pago'), findsOneWidget);
    });

    testWidgets('aprobar envía el evento', (tester) async {
      await pump(tester, loaded());
      await tester.tap(find.text('Aprobar').first);
      verify(() => bloc.add(const PaymentApproved('a'))).called(1);
    });

    testWidgets('rechazar pide confirmación y envía el motivo', (tester) async {
      await pump(tester, loaded());

      await tester.tap(find.text('Rechazar').first);
      await tester.pumpAndSettle();
      expect(find.text('¿Rechazar pago?'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Duplicado');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Rechazar'),
        ),
      );
      await tester.pumpAndSettle();
      verify(
        () => bloc.add(const PaymentRejected('a', reason: 'Duplicado')),
      ).called(1);
    });

    testWidgets('cancelar el rechazo no envía nada', (tester) async {
      await pump(tester, loaded());
      await tester.tap(find.text('Rechazar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any(that: isA<PaymentRejected>())));
    });

    testWidgets('las pestañas cambian el filtro', (tester) async {
      await pump(tester, loaded());
      await tester.tap(find.text('Rechazados'));
      verify(
        () => bloc.add(const PaymentsTabChanged(PaymentStatus.rejected)),
      ).called(1);
    });

    testWidgets('rechazados muestran el motivo y no tienen acciones', (
      tester,
    ) async {
      await pump(tester, loaded(tab: PaymentStatus.rejected));
      expect(find.text('No coincide'), findsOneWidget);
      expect(find.text('Aprobar'), findsNothing);
    });

    testWidgets('sin pendientes muestra "Todo al día"', (tester) async {
      await pump(
        tester,
        PaymentsState(
          status: PaymentsStatus.success,
          payments: [payment(id: 'c', status: PaymentStatus.approved)],
        ),
      );
      expect(find.text('Todo al día'), findsOneWidget);
    });

    for (final size in const [
      Size(320, 568),
      Size(412, 915),
      Size(760, 900),
      Size(1024, 768),
      Size(1920, 1080),
    ]) {
      testWidgets('sin overflow en ${size.width}x${size.height}', (
        tester,
      ) async {
        await pump(tester, loaded(), size: size);
        expect(tester.takeException(), isNull);
      });
    }

    group('web / pantallas anchas', () {
      double cardWidth(WidgetTester tester) =>
          tester.getSize(find.byType(PaymentCard).first).width;

      testWidgets('móvil: una columna a todo el ancho', (tester) async {
        await pump(tester, loaded());
        expect(cardWidth(tester), 390 - 2 * 12);
      });

      testWidgets('tablet: tarjetas en 2 columnas', (tester) async {
        await pump(tester, loaded(), size: const Size(900, 1400));
        expect(cardWidth(tester), (900 - 2 * 24 - 12) / 2);
      });

      testWidgets('escritorio: 3 columnas y pestañas sin estirarse', (
        tester,
      ) async {
        await pump(tester, loaded(), size: const Size(1400, 1200));
        expect(cardWidth(tester), (1400 - 2 * 24 - 2 * 12) / 3);
        expect(tester.getSize(find.byType(PaymentsTabs)).width, 560);
      });
    });
  });

  group('NewPaymentPage', () {
    late _MockNewPaymentBloc bloc;
    late GoRouter router;
    setUp(() => bloc = _MockNewPaymentBloc());

    Future<void> pump(
      WidgetTester tester, {
      NewPaymentState state = const NewPaymentState(),
      Size size = const Size(390, 1400),
    }) async {
      setSize(tester, size);
      when(() => bloc.state).thenReturn(state);
      router = GoRouter(
        initialLocation: AppRoutes.businessPayments,
        routes: [
          GoRoute(
            path: AppRoutes.businessPayments,
            builder: (_, _) => const Text('payments-page'),
            routes: [
              GoRoute(
                path: 'nuevo',
                builder: (_, _) => BlocProvider<NewPaymentBloc>.value(
                  value: bloc,
                  child: const NewPaymentPage(),
                ),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.push(AppRoutes.businessNewPayment);
      await tester.pumpAndSettle();
    }

    testWidgets('valida campos obligatorios', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Registrar pago'));
      await tester.pump();

      expect(find.text('Ingresa el nombre del cliente'), findsOneWidget);
      expect(find.text('Ingresa un monto mayor a cero'), findsOneWidget);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('la referencia solo se pide fuera de efectivo', (tester) async {
      await pump(tester);
      expect(find.text('REFERENCIA'), findsNothing);

      await tester.tap(find.text('Nequi'));
      await tester.pumpAndSettle();
      expect(find.text('REFERENCIA'), findsOneWidget);
    });

    testWidgets('chips de monto suman y el total se actualiza', (tester) async {
      await pump(tester);

      await tester.tap(find.text(r'+$50.000'));
      await tester.tap(find.text(r'+$20.000'));
      await tester.pump();

      expect(find.text('70.000'), findsOneWidget);
      expect(find.text(r'$70.000 COP'), findsOneWidget);
    });

    testWidgets('envía el pago con los datos del formulario', (tester) async {
      await pump(tester);

      await tester.enterText(
        find.byType(TextFormField).first,
        'Laura Restrepo',
      );
      await tester.tap(find.text('Pago total'));
      await tester.tap(find.text(r'+$100.000'));
      await tester.tap(find.text('Nequi'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), 'M999');
      await tester.tap(find.text('Registrar pago'));
      await tester.pump();

      verify(
        () => bloc.add(
          const NewPaymentSubmitted(
            NewPayment(
              customerName: 'Laura Restrepo',
              amount: 100000,
              method: PaymentMethod.nequi,
              concept: PaymentConcept.total,
              reference: 'M999',
            ),
          ),
        ),
      ).called(1);
    });

    testWidgets('al registrarse vuelve atrás con resultado', (tester) async {
      whenListen(
        bloc,
        Stream.fromIterable([
          NewPaymentState(
            status: NewPaymentStatus.success,
            created: payment(id: 'n', status: PaymentStatus.approved),
          ),
        ]),
        initialState: const NewPaymentState(),
      );
      setSize(tester);
      router = GoRouter(
        initialLocation: AppRoutes.businessPayments,
        routes: [
          GoRoute(
            path: AppRoutes.businessPayments,
            builder: (_, _) => const Text('payments-page'),
            routes: [
              GoRoute(
                path: 'nuevo',
                builder: (_, _) => BlocProvider<NewPaymentBloc>.value(
                  value: bloc,
                  child: const NewPaymentPage(),
                ),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      final result = router.push<bool>(AppRoutes.businessNewPayment);
      await tester.pumpAndSettle();

      expect(await result, isTrue);
      expect(find.text('payments-page'), findsOneWidget);
    });

    testWidgets('sin overflow en 320x568', (tester) async {
      await pump(tester, size: const Size(320, 568));
      expect(tester.takeException(), isNull);
    });

    group('web / pantallas anchas', () {
      testWidgets('resumen a la derecha que refleja el formulario', (
        tester,
      ) async {
        await pump(tester, size: const Size(1440, 900));

        expect(find.text('RESUMEN'), findsOneWidget);
        // Un solo botón (en el resumen), sin barra inferior.
        expect(find.text('Registrar pago'), findsOneWidget);
        // Formulario en dos columnas: "Método de pago" encabeza la columna
        // derecha, al lado y por encima de "Concepto" (columna izquierda).
        final concepto = tester.getTopLeft(find.text('CONCEPTO'));
        final metodo = tester.getTopLeft(find.text('MÉTODO DE PAGO'));
        expect(metodo.dx, greaterThan(concepto.dx));
        expect(metodo.dy, lessThan(concepto.dy));

        await tester.enterText(find.byType(TextFormField).first, 'Mateo Gómez');
        await tester.tap(find.text(r'+$50.000'));
        await tester.pump();
        expect(find.text('Mateo Gómez'), findsWidgets);
        expect(find.text(r'$50.000 COP'), findsOneWidget);
      });

      testWidgets('envía desde el botón del resumen', (tester) async {
        await pump(tester, size: const Size(1440, 900));

        await tester.enterText(find.byType(TextFormField).first, 'Ana');
        await tester.tap(find.text(r'+$20.000'));
        await tester.pump();
        await tester.tap(find.text('Registrar pago'));
        await tester.pump();

        verify(
          () => bloc.add(
            any(
              that: isA<NewPaymentSubmitted>()
                  .having((e) => e.payment.customerName, 'cliente', 'Ana')
                  .having((e) => e.payment.amount, 'monto', 20000),
            ),
          ),
        ).called(1);
      });

      for (final size in const [
        Size(760, 900),
        Size(900, 700),
        Size(1024, 768),
        Size(1920, 1080),
      ]) {
        testWidgets('sin overflow en ${size.width}x${size.height}', (
          tester,
        ) async {
          await pump(tester, size: size);
          expect(tester.takeException(), isNull);
        });
      }
    });
  });
}
