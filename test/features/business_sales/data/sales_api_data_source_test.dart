import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/features/business_reservations/data/datasources/reservations_api_data_source.dart';
import 'package:mi_cancha/features/business_sales/data/datasources/sales_api_data_source.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/new_sale.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/product.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/sale.dart';

import '../../../helpers/api_dio.dart';
import '../../../helpers/fake_http_adapter.dart';

Object? _body(Object? data) => data is String ? jsonDecode(data) : data;

Map<String, Object?> _sale({
  String? reservationId = 'r1',
  String status = 'ACTIVE',
  String? paymentMethod,
}) => {
  'id': 's1',
  'reservationId': reservationId,
  'customerName': 'Juan',
  'total': 75000,
  'note': null,
  'status': status,
  'voidReason': status == 'VOIDED' ? 'Error' : null,
  'voidedAt': status == 'VOIDED' ? '2026-10-28T23:30:00.000Z' : null,
  'createdAt': '2026-10-28T23:10:00.000Z',
  'items': [
    {
      'id': 'i1',
      'productId': 'p1',
      'productName': 'Gatorade',
      'unitPrice': 5000,
      'quantity': 12,
      'subtotal': 60000,
    },
    {
      'id': 'i2',
      'productId': null,
      'productName': 'Agua',
      'unitPrice': 2500,
      'quantity': 6,
      'subtotal': 15000,
    },
  ],
  'paymentMethod': paymentMethod,
};

void main() {
  late FakeHttpAdapter adapter;
  late SalesApiDataSource source;

  setUp(() {
    adapter = FakeHttpAdapter((_) => (200, _sale()));
    source = SalesApiDataSource(apiDio(adapter));
  });

  test('lee una venta con sus productos', () {
    final sale = SalesApiDataSource.saleFromJson(
      _sale(status: 'VOIDED', paymentMethod: 'EFECTIVO'),
    );
    expect(sale.total, 75000);
    expect(sale.isVoided, isTrue);
    expect(sale.voidReason, 'Error');
    expect(sale.items, hasLength(2));
    expect(sale.items.last.productId, isNull);
    expect(sale.itemsLabel, '12 × Gatorade · 6 × Agua');
    expect(sale.paymentMethod, 'EFECTIVO');
  });

  test('consumo de reserva: envía la reserva y no el pago', () async {
    await source.createSale(
      const NewSale(
        quantities: {'p1': 12, 'p2': 6, 'p3': 0},
        reservationId: 'r1',
      ),
    );
    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, endsWith('/business/sales'));
    expect(_body(request.data), {
      'reservationId': 'r1',
      'items': [
        {'productId': 'p1', 'quantity': 12},
        {'productId': 'p2', 'quantity': 6},
      ],
    });
  });

  test('venta suelta: envía el método de pago', () async {
    adapter.handler = (_) => (200, _sale(reservationId: null));
    final sale = await source.createSale(
      const NewSale(quantities: {'p1': 2}, paymentMethod: 'NEQUI'),
    );
    expect(_body(adapter.requests.single.data), {
      'items': [
        {'productId': 'p1', 'quantity': 2},
      ],
      'payment': {'method': 'NEQUI'},
    });
    expect(sale.isWalkIn, isTrue);
  });

  test('ventas del día con la fecha local', () async {
    adapter.handler = (_) => (200, [_sale()]);
    final sales = await source.getSales(DateTime(2026, 10, 28, 22));
    expect(adapter.requests.single.queryParameters, {'date': '2026-10-28'});
    expect(sales.single.status, SaleStatus.active);
  });

  test('anular envía el motivo', () async {
    adapter.handler = (_) => (200, _sale(status: 'VOIDED'));
    await source.voidSale('s1', 'Se registró dos veces');
    final request = adapter.requests.single;
    expect(request.path, endsWith('/business/sales/s1/void'));
    expect(_body(request.data), {'reason': 'Se registró dos veces'});
  });

  test('para vender pide los más vendidos; el catálogo, todos', () async {
    adapter.handler = (_) => (
      200,
      [
        {
          'id': 'p1',
          'name': 'Gatorade',
          'category': 'HIDRATANTE',
          'price': 5000,
          'isActive': true,
          'sold': 24,
        },
      ],
    );
    final products = await source.getProducts(includeInactive: false);
    expect(adapter.requests.last.queryParameters, {'sort': 'popular'});
    expect(products.single.category, ProductCategory.hidratante);
    expect(products.single.sold, 24);

    await source.getProducts(includeInactive: true);
    expect(adapter.requests.last.queryParameters, {'includeInactive': true});
  });

  test('crear un producto envía su categoría', () async {
    adapter.handler = (_) =>
        (200, {'id': 'p1', 'name': 'Agua', 'category': 'AGUA', 'price': 2500});
    await source.createProduct(
      name: 'Agua',
      category: ProductCategory.agua,
      price: 2500,
    );
    expect(_body(adapter.requests.single.data), {
      'name': 'Agua',
      'category': 'AGUA',
      'price': 2500,
    });
  });

  test('editar un producto solo envía lo que cambia', () async {
    adapter.handler = (_) =>
        (200, {'id': 'p1', 'name': 'Agua', 'price': 2500, 'isActive': false});
    final product = await source.updateProduct('p1', isActive: false);
    expect(_body(adapter.requests.single.data), {'isActive': false});
    expect(product.isActive, isFalse);
  });

  test('la reserva trae sus consumos y el total de consumos', () {
    final r = ReservationsApiDataSource.fromJson({
      'id': 'r1',
      'courtName': 'Cancha 1',
      'sport': 'FUTBOL',
      'start': '2026-10-28T23:00:00.000Z',
      'end': '2026-10-29T00:00:00.000Z',
      'customerName': 'Juan',
      'phone': '300',
      'totalPrice': 60000,
      'consumptionsTotal': 75000,
      'amountPaid': 60000,
      'status': 'CONFIRMED',
      'consumptions': [_sale()],
    });
    expect(r.consumptionsTotal, 75000);
    expect(r.consumptions.single.items, hasLength(2));
    expect(r.displayBalance, 75000);
  });
}
