import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/network/api_exception.dart';
import 'package:mi_cancha/core/session/business_modules.dart';
import 'package:mi_cancha/core/session/write_access.dart';
import 'package:mi_cancha/features/business_sales/data/datasources/inventory_api_data_source.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/cash_session.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/inventory.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/product.dart';
import 'package:mi_cancha/features/business_sales/domain/repositories/cash_repository.dart';
import 'package:mi_cancha/features/business_sales/domain/repositories/inventory_repository.dart';
import 'package:mi_cancha/features/business_sales/domain/usecases/cash_usecases.dart';
import 'package:mi_cancha/features/business_sales/domain/usecases/inventory_usecases.dart';
import 'package:mi_cancha/features/business_sales/domain/usecases/sales_usecases.dart';
import 'package:mi_cancha/features/business_sales/presentation/bloc/inventory_cubit.dart';
import 'package:mi_cancha/features/business_sales/presentation/bloc/sale_cart_cubit.dart';
import 'package:mi_cancha/features/business_sales/presentation/pages/inventory_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/api_dio.dart';
import '../../../helpers/fake_http_adapter.dart';

class _MockInventoryRepository extends Mock implements InventoryRepository {}

class _MockCashRepository extends Mock implements CashRepository {}

class _MockGetProducts extends Mock implements GetProducts {}

class _MockCreateSale extends Mock implements CreateSale {}

const _water = Product(
  id: 'p-agua',
  name: 'Agua',
  price: 2500,
  trackStock: true,
  stock: 30,
  minStock: 10,
);
const _gatorade = Product(
  id: 'p-gato',
  name: 'Gatorade',
  price: 5000,
  trackStock: true,
  stock: 4,
  minStock: 6,
);
const _ice = Product(
  id: 'p-hielo',
  name: 'Hielo',
  price: 3000,
  trackStock: true,
  stock: 0,
);
const _bibs = Product(id: 'p-petos', name: 'Petos', price: 2000);

const _overview = InventoryOverview(
  items: [_water, _gatorade, _ice, _bibs],
  tracked: 3,
  low: 1,
  out: 1,
);

StockMovement _movement(int quantity, int after) => StockMovement(
  id: 'mv-$after',
  productId: 'p-agua',
  productName: 'Agua',
  type: StockMovementType.entrada,
  quantity: quantity,
  stockAfter: after,
  createdAt: DateTime(2026, 10, 29, 9),
);

void main() {
  group('Product', () {
    test('stock bajo y agotado solo con control de stock', () {
      expect(_water.isLow, isFalse);
      expect(_gatorade.isLow, isTrue);
      expect(_gatorade.isOut, isFalse);
      expect(_ice.isOut, isTrue);
      expect(_ice.isLow, isTrue);
      expect(_bibs.isLow, isFalse);
      expect(_bibs.isOut, isFalse);
    });
  });

  group('InventoryApiDataSource', () {
    late FakeHttpAdapter adapter;
    late InventoryApiDataSource source;

    setUp(() {
      adapter = FakeHttpAdapter((_) => (200, const {}));
      source = InventoryApiDataSource(apiDio(adapter));
    });

    test('resumen con existencias y alertas', () async {
      adapter.handler = (_) => (
        200,
        {
          'items': [
            {
              'id': 'p-agua',
              'name': 'Agua',
              'category': 'AGUA',
              'price': 2500,
              'trackStock': true,
              'stock': 5,
              'minStock': 10,
              'lowStock': true,
            },
          ],
          'tracked': 1,
          'low': 1,
          'out': 0,
        },
      );
      final overview = await source.overview();
      expect(adapter.requests.single.path, '/business/inventory');
      expect(overview.low, 1);
      final water = overview.items.single;
      expect(water.trackStock, isTrue);
      expect(water.stock, 5);
      expect(water.minStock, 10);
      expect(water.isLow, isTrue);
    });

    test('entrada: envía solo lo que tiene valor', () async {
      adapter.handler = (_) => (
        201,
        {
          'id': 'mv-1',
          'productId': 'p-agua',
          'productName': 'Agua',
          'type': 'ENTRADA',
          'quantity': 24,
          'stockAfter': 30,
          'unitCost': 1200,
          'supplierName': 'Postobón',
          'note': null,
          'createdByName': 'Esteban',
          'createdAt': '2026-10-29T14:00:00.000Z',
        },
      );
      final movement = await source.addEntry(
        productId: 'p-agua',
        quantity: 24,
        unitCost: 1200,
        note: '  ',
      );
      final request = adapter.requests.single;
      expect(request.path, '/business/inventory/entries');
      final body = request.data is String
          ? jsonDecode(request.data as String)
          : request.data;
      expect(body, {'productId': 'p-agua', 'quantity': 24, 'unitCost': 1200});
      expect(movement.type, StockMovementType.entrada);
      expect(movement.stockAfter, 30);
      expect(movement.supplierName, 'Postobón');
    });

    test('control de stock va al producto', () async {
      await source.configure(
        productId: 'p-agua',
        trackStock: true,
        minStock: 8,
      );
      final request = adapter.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/business/products/p-agua');
    });
  });

  group('InventoryCubit', () {
    late _MockInventoryRepository repository;
    late _MockCashRepository cash;

    setUp(() {
      repository = _MockInventoryRepository();
      cash = _MockCashRepository();
      when(() => repository.overview()).thenAnswer((_) async => _overview);
      when(
        () => cash.suppliers(includeInactive: any(named: 'includeInactive')),
      ).thenAnswer((_) async => const <Supplier>[]);
    });

    InventoryCubit build() => InventoryCubit(
      getInventory: GetInventory(repository),
      addEntry: AddStockEntry(repository),
      adjustStock: AdjustStock(repository),
      configureStock: ConfigureStock(repository),
      getMovements: GetStockMovements(repository),
      getSuppliers: GetSuppliers(cash),
    );

    test('agotados y con stock bajo primero; filtros y búsqueda', () async {
      final cubit = build();
      await cubit.load();
      expect(cubit.state.visible.map((p) => p.name), [
        'Hielo',
        'Gatorade',
        'Agua',
        'Petos',
      ]);
      cubit.filter(InventoryFilter.low);
      expect(cubit.state.visible.single.name, 'Gatorade');
      cubit.filter(InventoryFilter.out);
      expect(cubit.state.visible.single.name, 'Hielo');
      cubit.filter(InventoryFilter.untracked);
      expect(cubit.state.visible.single.name, 'Petos');
      expect(cubit.state.countOf(InventoryFilter.untracked), 1);
      cubit
        ..filter(InventoryFilter.all)
        ..search('agu');
      expect(cubit.state.visible.single.name, 'Agua');
    });

    test('una entrada válida recarga el inventario', () async {
      when(
        () => repository.addEntry(
          productId: 'p-agua',
          quantity: 12,
          unitCost: null,
          supplierId: null,
          note: null,
        ),
      ).thenAnswer((_) async => _movement(12, 42));
      final cubit = build();
      final error = await cubit.addEntry((
        productId: 'p-agua',
        quantity: 12,
        unitCost: null,
        supplierId: null,
        note: null,
      ));
      expect(error, isNull);
      verify(() => repository.overview()).called(1);
    });

    test('valida antes de llamar a la API', () async {
      final cubit = build();
      expect(
        await cubit.addEntry((
          productId: 'p-agua',
          quantity: 0,
          unitCost: null,
          supplierId: null,
          note: null,
        )),
        'Escribe cuántas unidades entran.',
      );
      expect(
        await cubit.adjust((productId: 'p-agua', stock: 5, reason: ' ')),
        'Escribe el motivo del ajuste.',
      );
      verifyNever(() => repository.overview());
    });

    test('muestra el mensaje de la API en un conflicto', () async {
      when(
        () =>
            repository.adjust(productId: 'p-agua', stock: 30, reason: 'Conteo'),
      ).thenThrow(
        const ApiException(
          ApiErrorKind.conflict,
          message: 'El stock ya está en ese valor',
        ),
      );
      final cubit = build();
      expect(
        await cubit.adjust((productId: 'p-agua', stock: 30, reason: 'Conteo')),
        'El stock ya está en ese valor',
      );
    });
  });

  group('SaleCartCubit con stock', () {
    late _MockGetProducts getProducts;

    setUp(() {
      getProducts = _MockGetProducts();
      when(
        () => getProducts(false),
      ).thenAnswer((_) async => [_water, _gatorade, _ice, _bibs]);
    });

    SaleCartCubit build() =>
        SaleCartCubit(getProducts: getProducts, createSale: _MockCreateSale());

    test('no deja pasar del stock ni vender agotados', () async {
      final cubit = build();
      await cubit.load();
      cubit
        ..setQuantity('p-gato', 10)
        ..add('p-hielo')
        ..setQuantity('p-petos', 50);
      expect(cubit.state.quantityOf('p-gato'), 4);
      expect(cubit.state.quantityOf('p-hielo'), 0);
      expect(cubit.state.quantityOf('p-petos'), 50);
      expect(cubit.state.availableOf(_bibs), isNull);
    });
  });

  group('InventoryPage', () {
    late _MockInventoryRepository repository;

    setUp(() {
      repository = _MockInventoryRepository();
      when(() => repository.overview()).thenAnswer((_) async => _overview);
    });

    Future<void> pump(
      WidgetTester tester, {
      bool sales = true,
      Size size = const Size(1280, 900),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cash = _MockCashRepository();
      when(
        () => cash.suppliers(includeInactive: any(named: 'includeInactive')),
      ).thenAnswer((_) async => const <Supplier>[]);
      await tester.pumpWidget(
        BusinessModulesScope(
          notifier: BusinessModules()..update(sales: sales),
          child: WriteAccessScope(
            notifier: WriteAccess()..update(canWrite: true),
            child: MaterialApp(
              home: Scaffold(
                body: BlocProvider(
                  create: (_) => InventoryCubit(
                    getInventory: GetInventory(repository),
                    addEntry: AddStockEntry(repository),
                    adjustStock: AdjustStock(repository),
                    configureStock: ConfigureStock(repository),
                    getMovements: GetStockMovements(repository),
                    getSuppliers: GetSuppliers(cash),
                  )..load(),
                  child: const InventoryPage(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('sin el módulo muestra el aviso', (tester) async {
      await pump(tester, sales: false);
      expect(
        find.text('El módulo de Ventas e inventario no está activo'),
        findsOne,
      );
      verifyNever(() => repository.overview());
    });

    testWidgets('indicadores, estados y filtro de agotados', (tester) async {
      await pump(tester);
      expect(
        find.descendant(
          of: find.byKey(const Key('stat-out')),
          matching: find.text('1'),
        ),
        findsOne,
      );
      expect(find.text('Agotado'), findsOne);
      expect(find.text('Stock bajo'), findsWidgets);
      expect(find.text('Sin control'), findsWidgets);
      await tester.tap(find.byKey(const Key('inventory-filter-out')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inventory-p-hielo')), findsOne);
      expect(find.byKey(const Key('inventory-p-agua')), findsNothing);
    });

    testWidgets('entrada de mercancía desde el menú del producto', (
      tester,
    ) async {
      when(
        () => repository.addEntry(
          productId: 'p-hielo',
          quantity: 20,
          unitCost: 1500,
          supplierId: null,
          note: '',
        ),
      ).thenAnswer((_) async => _movement(20, 20));
      await pump(tester);
      await tester.tap(find.byKey(const Key('inventory-menu-p-hielo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrada de mercancía').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('entry-quantity')), '20');
      await tester.enterText(find.byKey(const Key('entry-cost')), '1500');
      await tester.pump();
      expect(find.text('Total de la compra: \$30.000'), findsOne);
      await tester.tap(find.byKey(const Key('entry-save')));
      await tester.pumpAndSettle();
      verify(
        () => repository.addEntry(
          productId: 'p-hielo',
          quantity: 20,
          unitCost: 1500,
          supplierId: null,
          note: '',
        ),
      ).called(1);
      expect(find.text('Entrada registrada: el stock se actualizó.'), findsOne);
    });

    testWidgets('en un teléfono angosto no se desborda', (tester) async {
      await pump(tester, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('inventory-entry')), findsOne);
    });
  });
}
