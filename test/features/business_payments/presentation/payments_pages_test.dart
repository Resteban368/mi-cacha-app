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
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/customer.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mi_cancha/features/business_payments/presentation/widgets/payment_card.dart';
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

    PaymentsState loaded({PaymentsFilter filter = const PaymentsFilter()}) =>
        PaymentsState(
          status: PaymentsStatus.success,
          payments: samplePayments,
          filter: filter,
        );

    testWidgets('solo muestra pagos aprobados, sin acciones ni pestañas', (
      tester,
    ) async {
      await pump(tester, loaded());

      expect(find.text('Pagos'), findsOneWidget);
      expect(find.byType(PaymentCard), findsOneWidget);
      expect(find.text(r'$100.000'), findsOneWidget);
      expect(find.text('Aprobar'), findsNothing);
      expect(find.text('Rechazar'), findsNothing);
      expect(find.text('Por validar'), findsNothing);
      expect(find.byTooltip('Nuevo pago'), findsOneWidget);
    });

    testWidgets('al tocar un pago se ve su detalle', (tester) async {
      await pump(tester, loaded());
      await tester.tap(find.byType(PaymentCard));
      await tester.pumpAndSettle();
      expect(find.text('Medio de pago'), findsOneWidget);
      expect(find.text('Registrado por'), findsOneWidget);
    });

    testWidgets('elegir un día envía el filtro', (tester) async {
      await pump(tester, loaded());
      await tester.tap(find.byKey(const Key('filter-method')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nequi').last);
      await tester.pumpAndSettle();
      verify(
        () => bloc.add(
          const PaymentsFilterChanged(
            PaymentsFilter(method: PaymentMethod.nequi),
          ),
        ),
      ).called(1);
    });

    testWidgets('con filtros sin resultados lo indica', (tester) async {
      await pump(
        tester,
        loaded(filter: const PaymentsFilter(court: 'Cancha inexistente')),
      );
      expect(find.text('Sin resultados'), findsOneWidget);
      expect(find.byKey(const Key('filter-clear')), findsOneWidget);
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

      testWidgets('escritorio: 3 columnas', (tester) async {
        await pump(tester, loaded(), size: const Size(1400, 1200));
        expect(cardWidth(tester), (1400 - 2 * 24 - 2 * 12) / 3);
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
      Reservation? reservation,
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
                builder: (_, routeState) => BlocProvider<NewPaymentBloc>.value(
                  value: bloc,
                  child: NewPaymentPage(
                    initialReservation: routeState.extra as Reservation?,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.push(AppRoutes.businessNewPayment, extra: reservation);
      await tester.pumpAndSettle();
      if (reservation == null) clearInteractions(bloc);
    }

    testWidgets('desde el detalle llega con la reserva y su saldo', (
      tester,
    ) async {
      final reservation = Reservation(
        id: 'r1',
        courtName: 'Cancha 1',
        sport: Sport.futbol,
        start: DateTime(2026, 10, 24, 16),
        end: DateTime(2026, 10, 24, 17),
        customerName: 'Valderrama',
        phone: '+57 320 922 0378',
        totalPrice: 70000,
        amountPaid: 20000,
        status: ReservationStatus.confirmed,
      );
      await pump(tester, reservation: reservation);

      verify(
        () => bloc.add(
          const NewPaymentTargetModeChanged(PaymentTargetMode.reservation),
        ),
      ).called(1);
      verify(
        () => bloc.add(NewPaymentReservationSelected(reservation)),
      ).called(1);
      expect(find.text('50.000'), findsOneWidget);
    });

    testWidgets('clientes: lista compacta que pide más al llegar al final', (
      tester,
    ) async {
      await pump(
        tester,
        state: NewPaymentState(
          customerSearchStatus: EntitySearchStatus.ready,
          customerResults: [
            for (var i = 0; i < 20; i++)
              Customer(
                id: 'c$i',
                name: 'Cliente $i',
                phone: '31100000$i',
                documentId: '1000$i',
              ),
          ],
          customerPage: 1,
          customerHasMore: true,
        ),
      );
      // Sin la fila de "Recientes" ni la etiqueta encima del buscador.
      expect(find.textContaining('Recientes'), findsNothing);
      expect(find.text('CLIENTES (20+)'), findsOneWidget);
      final list = find.byKey(const Key('payment-customer-list'));
      expect(tester.getSize(list).height, lessThanOrEqualTo(260));

      await tester.drag(list, const Offset(0, -3000));
      await tester.pump();
      verify(
        () => bloc.add(const NewPaymentCustomersNextPage()),
      ).called(greaterThanOrEqualTo(1));
    });

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
      expect(find.text('REFERENCIA (OPCIONAL)'), findsNothing);

      await tester.tap(find.text('Nequi'));
      await tester.pumpAndSettle();
      expect(find.text('REFERENCIA (OPCIONAL)'), findsOneWidget);
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
