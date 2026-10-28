import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/di/injection_container.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/core/session/write_access.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';
import 'package:mi_cancha/features/business_reservations/domain/usecases/booking_usecases.dart';
import 'package:mi_cancha/features/business_reservations/domain/usecases/get_day_reservations.dart';
import 'package:mi_cancha/features/business_reservations/presentation/bloc/reservation_detail/reservation_detail_cubit.dart';
import 'package:mi_cancha/features/business_reservations/presentation/widgets/reservation_detail_sheet.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/new_sale.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/product.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/sale.dart';
import 'package:mi_cancha/features/business_sales/domain/usecases/sales_usecases.dart';
import 'package:mi_cancha/features/business_sales/presentation/bloc/sale_cart_cubit.dart';
import 'package:mi_cancha/features/business_sales/presentation/widgets/sale_sheet.dart';
import 'package:mocktail/mocktail.dart';

class _MockGet extends Mock implements GetReservation {}

class _MockCancel extends Mock implements CancelReservation {}

class _MockStatus extends Mock implements UpdateReservationStatus {}

class _MockGetProducts extends Mock implements GetProducts {}

class _MockCreateSale extends Mock implements CreateSale {}

class _MockVoidSale extends Mock implements VoidSale {}

class _MockGetDay extends Mock implements GetDayReservations {}

final _start = DateTime.now().subtract(const Duration(minutes: 30));

Sale _sale({bool voided = false}) => Sale(
  id: 's1',
  reservationId: 'r1',
  customerName: 'Juan',
  total: 75000,
  status: voided ? SaleStatus.voided : SaleStatus.active,
  createdAt: _start,
  items: const [
    SaleItem(
      productName: 'Gatorade',
      unitPrice: 5000,
      quantity: 12,
      subtotal: 60000,
    ),
    SaleItem(
      productName: 'Agua',
      unitPrice: 2500,
      quantity: 6,
      subtotal: 15000,
    ),
  ],
);

Reservation _reservation({List<Sale> consumptions = const []}) => Reservation(
  id: 'r1',
  courtName: 'Cancha 1',
  sport: Sport.futbol,
  start: _start,
  end: _start.add(const Duration(hours: 1)),
  customerName: 'Juan',
  phone: '300',
  totalPrice: 60000,
  amountPaid: 60000,
  status: ReservationStatus.confirmed,
  consumptionsTotal: consumptions
      .where((s) => !s.isVoided)
      .fold(0, (sum, s) => sum + s.total),
  consumptions: consumptions,
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const NewSale(quantities: {}));
    registerFallbackValue((id: 's1', reason: 'x'));
    registerFallbackValue(DateTime(2026));
  });

  late _MockGet get;
  late _MockGetProducts getProducts;
  late _MockCreateSale createSale;
  late _MockVoidSale voidSale;
  late _MockGetDay getDay;

  setUp(() {
    getDay = _MockGetDay();
    get = _MockGet();
    getProducts = _MockGetProducts();
    createSale = _MockCreateSale();
    voidSale = _MockVoidSale();
    when(() => getProducts(false)).thenAnswer(
      (_) async => const [
        Product(
          id: 'p1',
          name: 'Gatorade',
          price: 5000,
          category: ProductCategory.hidratante,
          sold: 24,
        ),
        Product(
          id: 'p2',
          name: 'Agua',
          price: 2500,
          category: ProductCategory.agua,
        ),
      ],
    );
    sl.registerFactory(
      () => SaleCartCubit(
        getProducts: getProducts,
        createSale: createSale,
        getDayReservations: getDay,
      ),
    );
  });

  tearDown(() => sl.unregister<SaleCartCubit>());

  Future<void> pumpDetail(
    WidgetTester tester,
    Reservation r, {
    Size size = const Size(1200, 1800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      WriteAccessScope(
        notifier: WriteAccess()..update(canWrite: true),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showReservationDetail(
                  context,
                  reservation: r,
                  createCubit: () => ReservationDetailCubit(
                    getReservation: get,
                    cancelReservation: _MockCancel(),
                    updateStatus: _MockStatus(),
                    voidSale: voidSale,
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('agregar consumo: carga los productos y suma al saldo', (
    tester,
  ) async {
    final empty = _reservation();
    final withSale = _reservation(consumptions: [_sale()]);
    var loads = 0;
    when(
      () => get(any()),
    ).thenAnswer((_) async => loads++ == 0 ? empty : withSale);
    when(() => createSale(any())).thenAnswer((_) async => _sale());

    await pumpDetail(tester, empty);
    // Pagada la cancha: sin saldo no ofrece pagar.
    expect(find.byKey(const Key('register-payment')), findsNothing);

    await tester.tap(find.byKey(const Key('add-consumption')));
    await tester.pumpAndSettle();
    expect(find.text('Agregar consumo'), findsWidgets);

    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byKey(const Key('add-p1')));
    }
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const Key('add-p2')));
    }
    await tester.pump();
    expect(find.text(r'Cargar $75.000 a la cuenta'), findsOneWidget);

    await tester.tap(find.byKey(const Key('submit-sale')));
    await tester.pumpAndSettle();

    final sent =
        verify(() => createSale(captureAny())).captured.single as NewSale;
    expect(sent.reservationId, 'r1');
    expect(sent.quantities, {'p1': 12, 'p2': 6});
    expect(find.text('12 × Gatorade · 6 × Agua'), findsOneWidget);
    expect(find.text('Consumos'), findsOneWidget);
    // Ahora el saldo son los consumos: se puede cobrar.
    expect(find.byKey(const Key('register-payment')), findsOneWidget);
  });

  testWidgets('la cuadrícula marca el más vendido y cada categoría', (
    tester,
  ) async {
    final r = _reservation();
    when(() => get(any())).thenAnswer((_) async => r);
    await pumpDetail(tester, r);
    await tester.tap(find.byKey(const Key('add-consumption')));
    await tester.pumpAndSettle();

    // Solo Gatorade tiene ventas: es el único "Top".
    expect(find.byKey(const Key('top-p1')), findsOneWidget);
    expect(find.byKey(const Key('top-p2')), findsNothing);
    // Ícono en la tarjeta y en el chip de su categoría.
    expect(find.byIcon(Icons.bolt_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.water_drop_outlined), findsNWidgets(2));
    // Resumen al costado en pantallas anchas.
    expect(find.text('Aún no has agregado productos.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('product-p2')));
    await tester.pump();
    expect(find.text('1 × Agua'), findsOneWidget);
  });

  testWidgets('busca, filtra por categoría y vacía el carrito', (tester) async {
    final r = _reservation();
    when(() => get(any())).thenAnswer((_) async => r);
    await pumpDetail(tester, r);
    await tester.tap(find.byKey(const Key('add-consumption')));
    await tester.pumpAndSettle();

    // Encabezado con los datos del turno.
    expect(find.text('Turno activo'), findsOneWidget);
    expect(find.text('Juan'), findsWidgets);

    await tester.tap(find.byKey(const Key('category-AGUA')));
    await tester.pump();
    expect(find.byKey(const Key('product-p1')), findsNothing);
    expect(find.byKey(const Key('product-p2')), findsOneWidget);
    await tester.tap(find.byKey(const Key('category-all')));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('product-search')), 'gato');
    await tester.pump();
    expect(find.byKey(const Key('product-p1')), findsOneWidget);
    expect(find.byKey(const Key('product-p2')), findsNothing);

    await tester.tap(find.byKey(const Key('add-p1')));
    await tester.pump();
    expect(find.text('1 × Gatorade'), findsOneWidget);
    await tester.tap(find.byKey(const Key('clear-cart')));
    await tester.pump();
    expect(find.text('Aún no has agregado productos.'), findsOneWidget);
  });

  testWidgets('cobrar ya: envía el pago con el consumo y la nota', (
    tester,
  ) async {
    final r = _reservation();
    when(() => get(any())).thenAnswer((_) async => r);
    when(() => createSale(any())).thenAnswer((_) async => _sale());
    await pumpDetail(tester, r);
    await tester.tap(find.byKey(const Key('add-consumption')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-p2')));
    await tester.tap(find.byKey(const Key('mode-charge-now')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('method-NEQUI')));
    await tester.tap(find.byKey(const Key('open-note')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('sale-note')), 'Bien fría');
    await tester.tap(find.byKey(const Key('sale-note-save')));
    await tester.pumpAndSettle();
    expect(find.text(r'Cobrar $2.500'), findsOneWidget);

    await tester.tap(find.byKey(const Key('submit-sale')));
    await tester.pumpAndSettle();
    final sent =
        verify(() => createSale(captureAny())).captured.single as NewSale;
    expect(sent.reservationId, 'r1');
    expect(sent.paymentMethod, 'NEQUI');
    expect(sent.note, 'Bien fría');
  });

  for (final size in const [Size(320, 640), Size(390, 844)]) {
    testWidgets('carrito en celular de ${size.width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSaleSheet(context),
                child: const Text('vender'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('vender'));
      await tester.pumpAndSettle();
      // El primer producto se ve completo sin desplazar.
      await tester.tap(find.byKey(const Key('add-p1')));
      await tester.pump();
      // Venta suelta: método de pago abajo y "Cobrar".
      expect(find.byKey(const Key('method-EFECTIVO')), findsOneWidget);
      expect(find.text(r'Cobrar $5.000'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  Future<void> openWalkIn(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSaleSheet(context),
              child: const Text('vender'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('vender'));
    await tester.pumpAndSettle();
  }

  testWidgets('venta nueva asociada a una reserva de hoy', (tester) async {
    final cancelled = Reservation(
      id: 'r9',
      courtName: 'Cancha 2',
      sport: Sport.futbol,
      start: _start,
      end: _start.add(const Duration(hours: 1)),
      customerName: 'Cancelado',
      phone: '1',
      totalPrice: 1,
      amountPaid: 0,
      status: ReservationStatus.cancelled,
    );
    when(
      () => getDay(any()),
    ).thenAnswer((_) async => [_reservation(), cancelled]);
    when(() => createSale(any())).thenAnswer((_) async => _sale());
    await openWalkIn(tester);

    await tester.tap(find.byKey(const Key('add-p2')));
    await tester.tap(find.byKey(const Key('destination-reservation')));
    await tester.pumpAndSettle();
    // Sin reserva elegida no se envía.
    await tester.tap(find.byKey(const Key('submit-sale')));
    await tester.pump();
    expect(
      find.text('Elige la reserva a la que se asocia la venta.'),
      findsOneWidget,
    );
    verifyNever(() => createSale(any()));

    await tester.tap(find.byKey(const Key('choose-reservation')));
    await tester.pumpAndSettle();
    // Solo las reservas que aceptan consumos.
    expect(find.byKey(const Key('pick-r9')), findsNothing);
    await tester.tap(find.byKey(const Key('pick-r1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('linked-reservation')), findsOneWidget);
    expect(find.text('RESUMEN DE CONSUMO'), findsOneWidget);
    expect(find.text(r'Cargar $2.500 a la cuenta'), findsOneWidget);

    await tester.tap(find.byKey(const Key('submit-sale')));
    await tester.pumpAndSettle();
    final sent =
        verify(() => createSale(captureAny())).captured.single as NewSale;
    expect(sent.reservationId, 'r1');
    expect(sent.paymentMethod, isNull);
  });

  testWidgets('volver a venta suelta la cobra en el momento', (tester) async {
    when(() => getDay(any())).thenAnswer((_) async => [_reservation()]);
    when(() => createSale(any())).thenAnswer((_) async => _sale());
    await openWalkIn(tester);

    await tester.tap(find.byKey(const Key('add-p2')));
    await tester.tap(find.byKey(const Key('destination-reservation')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('destination-walk-in')));
    await tester.pumpAndSettle();
    expect(find.text(r'Cobrar $2.500'), findsOneWidget);

    await tester.tap(find.byKey(const Key('submit-sale')));
    await tester.pumpAndSettle();
    final sent =
        verify(() => createSale(captureAny())).captured.single as NewSale;
    expect(sent.reservationId, isNull);
    expect(sent.paymentMethod, 'EFECTIVO');
  });

  testWidgets('anular un consumo pide el motivo', (tester) async {
    final withSale = _reservation(consumptions: [_sale()]);
    final voided = _reservation(consumptions: [_sale(voided: true)]);
    var loads = 0;
    when(
      () => get(any()),
    ).thenAnswer((_) async => loads++ == 0 ? withSale : voided);
    when(() => voidSale(any())).thenAnswer((_) async => _sale(voided: true));

    await pumpDetail(tester, withSale);
    await tester.tap(find.byKey(const Key('void-s1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('void-reason')), 'Error');
    await tester.pump();
    await tester.tap(find.byKey(const Key('void-confirm')));
    await tester.pumpAndSettle();

    verify(() => voidSale((id: 's1', reason: 'Error'))).called(1);
    expect(find.text('Consumo anulado.'), findsOneWidget);
    expect(find.byKey(const Key('void-s1')), findsNothing);
  });
}
