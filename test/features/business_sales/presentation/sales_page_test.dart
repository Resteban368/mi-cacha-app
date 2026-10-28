import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/session/write_access.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/sale.dart';
import 'package:mi_cancha/features/business_sales/domain/usecases/sales_usecases.dart';
import 'package:mi_cancha/features/business_sales/presentation/bloc/sales_cubit.dart';
import 'package:mi_cancha/features/business_sales/presentation/pages/sales_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetSales extends Mock implements GetSales {}

class _MockVoidSale extends Mock implements VoidSale {}

final _now = DateTime.now();

Sale _sale(
  String id,
  int total, {
  String? reservationId,
  String? method,
  bool voided = false,
  String product = 'Agua 600 ml',
  String? customer,
}) => Sale(
  id: id,
  reservationId: reservationId,
  customerName: customer,
  total: total,
  status: voided ? SaleStatus.voided : SaleStatus.active,
  voidReason: voided ? 'Reserva cancelada' : null,
  createdAt: _now,
  paymentMethod: method,
  courtName: reservationId == null ? null : 'Sintética 1',
  reservationStart: reservationId == null ? null : _now,
  items: [
    SaleItem(
      productName: product,
      unitPrice: total,
      quantity: 1,
      subtotal: total,
    ),
  ],
);

final _sales = [
  _sale('s1', 15000, method: 'EFECTIVO'),
  _sale('s2', 48000, method: 'EFECTIVO', product: 'Cerveza Poker'),
  _sale('s3', 5000, method: 'NEQUI'),
  _sale('s4', 15000, reservationId: 'r1', customer: 'Pedro Prueba'),
  _sale(
    's5',
    9500,
    reservationId: 'r1',
    customer: 'Pedro Prueba',
    method: 'EFECTIVO',
  ),
  _sale('s6', 7500, reservationId: 'r2', customer: 'Juan', voided: true),
];

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(DateTime(2026));
    registerFallbackValue((id: 's1', reason: 'x'));
  });

  late _MockGetSales getSales;
  late _MockVoidSale voidSale;

  setUp(() {
    getSales = _MockGetSales();
    voidSale = _MockVoidSale();
    when(() => getSales(any())).thenAnswer((_) async => _sales);
  });

  test('arqueo, pestañas y filtros del estado', () {
    final state = SalesState(day: _now, load: SalesLoad.ready, sales: _sales);
    expect(state.total, 92500);
    expect(state.walkInTotal, 68000);
    expect(state.consumptionsTotal, 24500);
    expect(state.byMethod.first.key, 'EFECTIVO');
    expect(state.byMethod.first.value, 72500);
    expect(state.chargedToReservations, 15000);
    expect(state.voidedCount, 1);
    expect(state.countOf(SalesTab.walkIn), 3);
    expect(state.countOf(SalesTab.consumptions), 2);
    expect(
      state.copyWith(method: () => chargedToReservation).visible.single.id,
      's4',
    );
    expect(state.copyWith(query: 'poker').visible.single.id, 's2');
    expect(state.copyWith(query: 'pedro').visible, hasLength(2));
  });

  Future<SalesCubit> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = SalesCubit(getSales: getSales, voidSale: voidSale);
    await tester.pumpWidget(
      WriteAccessScope(
        notifier: WriteAccess()..update(canWrite: true),
        child: MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit..load(),
              child: const SalesPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  for (final size in const [Size(390, 2400), Size(1440, 2000)]) {
    testWidgets('caja del día sin desbordes en ${size.width.toInt()} px', (
      tester,
    ) async {
      await pump(tester, size);
      expect(find.text('Ventas y caja de hoy'), findsOneWidget);
      expect(find.text('ARQUEO POR MÉTODOS'), findsOneWidget);
      expect(find.text('Anulaciones (1)'), findsOneWidget);
      expect(find.text('Por cobrar con la reserva'), findsOneWidget);
      expect(find.text('Cobrado · Nequi'), findsOneWidget);
      expect(find.text('Motivo: Reserva cancelada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pestaña de anuladas y anular desde el menú', (tester) async {
    when(() => voidSale(any())).thenAnswer(
      (_) async => _sale('s1', 15000, method: 'EFECTIVO', voided: true),
    );
    await pump(tester, const Size(1440, 2000));

    await tester.ensureVisible(find.byKey(const Key('tab-voided')));
    await tester.tap(find.byKey(const Key('tab-voided')));
    await tester.pumpAndSettle();
    expect(find.text('1 de 6'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('tab-all')));
    await tester.tap(find.byKey(const Key('tab-all')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sale-menu-s1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('void-s1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('void-reason')), 'Error');
    await tester.pump();
    await tester.tap(find.byKey(const Key('void-confirm')));
    await tester.pumpAndSettle();

    verify(() => voidSale((id: 's1', reason: 'Error'))).called(1);
    expect(find.text('Venta anulada.'), findsOneWidget);
    expect(find.text('Anulaciones (2)'), findsOneWidget);
  });
}
