import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_cancha/core/session/write_access.dart';
import 'package:mi_cancha/features/business_payments/presentation/pages/new_payment_page.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/sale.dart';
import 'package:mi_cancha/features/business_sales/presentation/widgets/sale_detail_sheet.dart';

final _start = DateTime(2026, 10, 29, 10);

Sale _sale(
  String id,
  int total, {
  int minute = 0,
  int? pending,
  bool paid = false,
  String? method,
  String? reservationId = 'r1',
}) => Sale(
  id: id,
  reservationId: reservationId,
  customerName: reservationId == null ? null : 'Pepe',
  total: total,
  status: SaleStatus.active,
  createdAt: DateTime(2026, 10, 29, 9, minute),
  paymentMethod: method,
  courtName: reservationId == null ? null : 'Cancha 2',
  reservationStart: reservationId == null ? null : _start,
  reservationPaid: paid,
  reservationPending: pending,
  items: [
    SaleItem(
      productName: 'Paca de agua',
      unitPrice: total,
      quantity: 1,
      subtotal: total,
    ),
  ],
);

Reservation _reservation({
  required int paid,
  int consumptions = 57000,
  List<Sale> sales = const [],
}) => Reservation(
  id: 'r1',
  courtName: 'Cancha 2',
  sport: Sport.futbol,
  start: _start,
  end: _start.add(const Duration(hours: 1)),
  customerName: 'Pepe',
  phone: '300',
  totalPrice: 60000,
  consumptionsTotal: consumptions,
  amountPaid: paid,
  status: ReservationStatus.confirmed,
  consumptions: sales,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('amountToCover', () {
    final beers = _sale('cerveza', 50000, minute: 20, paid: true, pending: 0);
    final water = _sale('agua', 7000, minute: 46, pending: 7000);

    test('cancha y cervezas pagadas: solo falta el agua', () {
      final r = _reservation(paid: 110000, sales: [beers, water]);
      expect(amountToCover(water, r), 7000);
    });

    test('sin pagar nada, cubrir el agua exige la cancha y lo anterior', () {
      final unpaidBeers = _sale('cerveza', 50000, minute: 20, pending: 50000);
      final r = _reservation(paid: 0, sales: [unpaidBeers, water]);
      expect(amountToCover(water, r), 117000);
      // Las cervezas se cargaron antes: el agua no cuenta para cubrirlas.
      expect(amountToCover(unpaidBeers, r), 110000);
    });
  });

  test('"Nuevo pago" toma la reserva y el monto de la ruta', () {
    final r = _reservation(paid: 110000);
    final withAmount = NewPaymentPage.fromExtra(
      NewPaymentArgs(reservation: r, amount: 7000),
    );
    expect(withAmount.initialReservation, r);
    expect(withAmount.initialAmount, 7000);
    expect(NewPaymentPage.fromExtra(r).initialAmount, isNull);
    expect(NewPaymentPage.fromExtra(null).initialReservation, isNull);
  });

  Future<void> open(WidgetTester tester, Sale sale, {Size? size}) async {
    tester.view.physicalSize = size ?? const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      WriteAccessScope(
        notifier: WriteAccess()..update(canWrite: true),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSaleDetail(
                  context,
                  sale: sale,
                  loadReservation: (_) async => _reservation(paid: 110000),
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

  testWidgets('consumo por cobrar: reserva, pendiente y cobrar', (
    tester,
  ) async {
    await open(tester, _sale('agua', 7000, pending: 7000));
    expect(find.text('Consumo de cancha'), findsOneWidget);
    expect(find.text('1 × Paca de agua'), findsOneWidget);
    expect(find.text('Cargado a la reserva'), findsOneWidget);
    expect(find.text(r'Faltan $7.000'), findsOneWidget);
    expect(find.byKey(const Key('sale-detail-reservation')), findsOneWidget);
    expect(find.text('Pepe'), findsOneWidget);
    expect(find.byKey(const Key('sale-detail-open-reservation')), findsOne);
    expect(find.byKey(const Key('sale-detail-charge')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('consumo pagado con la reserva: sin botón de cobrar', (
    tester,
  ) async {
    await open(tester, _sale('cerveza', 50000, paid: true, pending: 0));
    expect(find.text('Pagado con la reserva'), findsOneWidget);
    expect(find.byKey(const Key('sale-detail-charge')), findsNothing);
    expect(find.byKey(const Key('sale-detail-open-reservation')), findsOne);
  });

  testWidgets('venta de mostrador: sin reserva', (tester) async {
    await open(
      tester,
      _sale('v', 5000, method: 'EFECTIVO', reservationId: null),
      size: const Size(360, 740),
    );
    expect(find.text('Venta de mostrador'), findsOneWidget);
    expect(find.text('Cobrado · Efectivo'), findsOneWidget);
    expect(find.byKey(const Key('sale-detail-reservation')), findsNothing);
    expect(find.byKey(const Key('sale-detail-charge')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
