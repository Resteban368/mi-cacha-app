import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/session/business_modules.dart';
import 'package:mi_cancha/core/session/write_access.dart';
import 'package:mi_cancha/core/usecase/usecase.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/cash_session.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/sale.dart';
import 'package:mi_cancha/features/business_sales/domain/usecases/cash_usecases.dart';
import 'package:mi_cancha/features/business_sales/domain/usecases/sales_usecases.dart';
import 'package:mi_cancha/features/business_sales/presentation/bloc/cash_cubit.dart';
import 'package:mi_cancha/features/business_sales/presentation/bloc/sales_cubit.dart';
import 'package:mi_cancha/features/business_sales/presentation/pages/sales_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetSales extends Mock implements GetSales {}

class _MockVoidSale extends Mock implements VoidSale {}

class _MockCashStatus extends Mock implements GetCashStatus {}

class _MockOpenCash extends Mock implements OpenCash {}

class _MockCloseCash extends Mock implements CloseCash {}

class _MockCashHistory extends Mock implements GetCashHistory {}

class _MockAddExpense extends Mock implements AddCashExpense {}

class _MockGetSuppliers extends Mock implements GetSuppliers {}

class _MockSaveSupplier extends Mock implements SaveSupplier {}

const _postobon = Supplier(id: 'sup-1', name: 'Postobón');

CashSession _cash({int? counted}) => CashSession(
  id: 'cs-1',
  openingCash: 50000,
  openedAt: _now,
  openedByName: 'Esteban',
  expectedCash: 122500,
  closedAt: counted == null ? null : _now,
  countedCash: counted,
  difference: counted == null ? null : counted - 122500,
  methods: const [
    CashMethodTotal(
      code: 'EFECTIVO',
      name: 'Efectivo',
      count: 4,
      amount: 72500,
    ),
    CashMethodTotal(code: 'NEQUI', name: 'Nequi', count: 1, amount: 5000),
  ],
  collected: 77500,
);

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
    registerFallbackValue(const NoParams());
    registerFallbackValue((amount: 0, note: null as String?));
    registerFallbackValue((supplierId: '', amount: 0, method: '', concept: ''));
    registerFallbackValue((
      id: null as String?,
      name: '',
      documentId: null as String?,
      phone: null as String?,
      notes: null as String?,
    ));
  });

  late _MockGetSales getSales;
  late _MockVoidSale voidSale;
  late _MockCashStatus cashStatus;
  late _MockOpenCash openCash;
  late _MockCloseCash closeCash;
  late _MockAddExpense addExpense;
  late _MockGetSuppliers getSuppliers;
  late _MockSaveSupplier saveSupplier;

  setUp(() {
    addExpense = _MockAddExpense();
    getSuppliers = _MockGetSuppliers();
    saveSupplier = _MockSaveSupplier();
    when(() => getSuppliers(false)).thenAnswer((_) async => [_postobon]);
    getSales = _MockGetSales();
    voidSale = _MockVoidSale();
    cashStatus = _MockCashStatus();
    openCash = _MockOpenCash();
    closeCash = _MockCloseCash();
    when(
      () => cashStatus(any()),
    ).thenAnswer((_) async => CashStatus(session: _cash()));
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
            body: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: cubit..load()),
                BlocProvider(
                  create: (_) => CashCubit(
                    getStatus: cashStatus,
                    openCash: openCash,
                    closeCash: closeCash,
                    getHistory: _MockCashHistory(),
                    addExpense: addExpense,
                    getSuppliers: getSuppliers,
                    saveSupplier: saveSupplier,
                  )..load(),
                ),
              ],
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

  testWidgets('cuadre de caja: muestra el faltante y cierra', (tester) async {
    when(
      () => closeCash(any()),
    ).thenAnswer((_) async => _cash(counted: 120000));
    await pump(tester, const Size(1440, 2000));
    expect(find.text('¿Listo para el cuadre de caja?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cash-close')));
    await tester.pumpAndSettle();
    expect(find.text(r'$122.500'), findsWidgets);
    await tester.enterText(find.byKey(const Key('cash-counted')), '120000');
    await tester.pump();
    expect(find.text(r'Faltante −$2.500'), findsOneWidget);

    when(
      () => cashStatus(any()),
    ).thenAnswer((_) async => CashStatus(lastClosed: _cash(counted: 120000)));
    await tester.tap(find.byKey(const Key('cash-close-confirm')));
    await tester.pumpAndSettle();

    verify(() => closeCash((amount: 120000, note: ''))).called(1);
    expect(find.text(r'Caja cerrada · Faltante −$2.500.'), findsOneWidget);
    expect(find.byKey(const Key('cash-open')), findsOneWidget);
  });

  testWidgets('pago a proveedor desde la caja abierta', (tester) async {
    when(() => addExpense(any())).thenAnswer(
      (_) async => CashExpense(
        id: 'ex-1',
        supplierName: 'Postobón',
        amount: 30000,
        method: 'EFECTIVO',
        concept: 'Bebidas',
        createdAt: _now,
      ),
    );
    await pump(tester, const Size(1440, 2000));

    await tester.tap(find.byKey(const Key('cash-expense')));
    await tester.pumpAndSettle();
    // Un solo proveedor: queda elegido.
    expect(find.text('Postobón'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('expense-amount')), '30000');
    await tester.enterText(find.byKey(const Key('expense-concept')), 'Bebidas');
    await tester.tap(find.byKey(const Key('expense-save')));
    await tester.pumpAndSettle();

    verify(
      () => addExpense((
        supplierId: 'sup-1',
        amount: 30000,
        method: 'EFECTIVO',
        concept: 'Bebidas',
      )),
    ).called(1);
    expect(find.text('Pago a proveedor registrado.'), findsOneWidget);
  });

  testWidgets('registrar un proveedor sin salir del pago', (tester) async {
    when(() => getSuppliers(false)).thenAnswer((_) async => []);
    when(() => saveSupplier(any())).thenAnswer((_) async {
      when(() => getSuppliers(false)).thenAnswer(
        (_) async => [const Supplier(id: 'sup-9', name: 'Hielo Polar')],
      );
      return const Supplier(id: 'sup-9', name: 'Hielo Polar');
    });
    await pump(tester, const Size(1440, 2000));

    await tester.tap(find.byKey(const Key('cash-expense')));
    await tester.pumpAndSettle();
    expect(find.text('Aún no tienes proveedores registrados.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('expense-new-supplier')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('supplier-name')),
      'Hielo Polar',
    );
    await tester.tap(find.byKey(const Key('supplier-save')));
    await tester.pumpAndSettle();

    expect(find.text('Hielo Polar'), findsOneWidget);
    expect(find.byKey(const Key('expense-supplier')), findsOneWidget);
  });

  testWidgets('el cuadre descuenta los pagos en efectivo', (tester) async {
    final withExpense = CashSession(
      id: 'cs-1',
      openingCash: 50000,
      openedAt: _now,
      expectedCash: 92500,
      methods: _cash().methods,
      collected: 77500,
      expenses: [
        CashExpense(
          id: 'ex-1',
          supplierName: 'Postobón',
          amount: 30000,
          method: 'EFECTIVO',
          concept: 'Bebidas',
          createdAt: _now,
        ),
      ],
      expensesTotal: 30000,
      cashExpensesTotal: 30000,
    );
    when(
      () => cashStatus(any()),
    ).thenAnswer((_) async => CashStatus(session: withExpense));
    await pump(tester, const Size(1440, 2000));

    await tester.tap(find.byKey(const Key('cash-close')));
    await tester.pumpAndSettle();
    expect(find.text('Pagos a proveedores en efectivo'), findsOneWidget);
    expect(find.text(r'−$30.000'), findsWidgets);
    expect(find.text('Postobón · Bebidas'), findsOneWidget);
    expect(find.text(r'$92.500'), findsWidgets);
    await tester.enterText(find.byKey(const Key('cash-counted')), '92500');
    await tester.pump();
    expect(find.text('Cuadra'), findsOneWidget);
  });

  testWidgets('abrir caja con la base', (tester) async {
    when(() => cashStatus(any())).thenAnswer((_) async => const CashStatus());
    when(() => openCash(any())).thenAnswer((_) async => _cash());
    await pump(tester, const Size(1440, 2000));
    expect(find.text('Caja cerrada'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cash-open')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cash-opening')), '50000');
    when(
      () => cashStatus(any()),
    ).thenAnswer((_) async => CashStatus(session: _cash()));
    await tester.tap(find.byKey(const Key('cash-open-confirm')));
    await tester.pumpAndSettle();

    verify(() => openCash((amount: 50000, note: ''))).called(1);
    expect(find.text('Caja abierta.'), findsOneWidget);
    expect(find.byKey(const Key('cash-close')), findsOneWidget);
  });

  testWidgets('sin el módulo de Ventas muestra el aviso', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      BusinessModulesScope(
        notifier: BusinessModules(),
        child: MaterialApp(
          home: Scaffold(
            body: BlocProvider(
              create: (_) => SalesCubit(getSales: getSales, voidSale: voidSale),
              child: const SalesPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('sales-module-locked')), findsOneWidget);
    expect(find.text('El módulo de Ventas no está activo'), findsOneWidget);
    verifyNever(() => getSales(any()));
  });

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
