import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/network/api_exception.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/new_sale.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/product.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/sale.dart';
import 'package:mi_cancha/features/business_sales/domain/usecases/sales_usecases.dart';
import 'package:mi_cancha/features/business_sales/presentation/bloc/sale_cart_cubit.dart';
import 'package:mi_cancha/features/business_sales/presentation/bloc/sales_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetProducts extends Mock implements GetProducts {}

class _MockCreateSale extends Mock implements CreateSale {}

class _MockGetSales extends Mock implements GetSales {}

class _MockVoidSale extends Mock implements VoidSale {}

const _drink = Product(id: 'p1', name: 'Gatorade', price: 5000);
const _water = Product(id: 'p2', name: 'Agua', price: 2500);

Sale _sale(
  String id,
  int total, {
  String? reservationId,
  bool voided = false,
}) => Sale(
  id: id,
  reservationId: reservationId,
  total: total,
  status: voided ? SaleStatus.voided : SaleStatus.active,
  createdAt: DateTime(2026, 10, 28, 18),
  items: const [],
);

void main() {
  setUpAll(() {
    registerFallbackValue(const NewSale(quantities: {}));
    registerFallbackValue(DateTime(2026));
    registerFallbackValue((id: 's1', reason: 'x'));
  });

  group('SaleCartCubit', () {
    late _MockGetProducts getProducts;
    late _MockCreateSale createSale;

    setUp(() {
      getProducts = _MockGetProducts();
      createSale = _MockCreateSale();
      when(() => getProducts(false)).thenAnswer((_) async => [_drink, _water]);
    });

    SaleCartCubit build() =>
        SaleCartCubit(getProducts: getProducts, createSale: createSale);

    blocTest<SaleCartCubit, SaleCartState>(
      '12 Gatorade y 6 aguas suman 75.000',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit
          ..setQuantity('p1', 12)
          ..add('p2')
          ..setQuantity('p2', 6);
      },
      verify: (cubit) {
        expect(cubit.state.total, 75000);
        expect(cubit.state.units, 18);
      },
    );

    blocTest<SaleCartCubit, SaleCartState>(
      'quitar hasta cero saca el producto del carrito',
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit
          ..add('p1')
          ..remove('p1')
          ..remove('p1');
      },
      verify: (cubit) => expect(cubit.state.isEmpty, isTrue),
    );

    blocTest<SaleCartCubit, SaleCartState>(
      'consumo de reserva: no envía método de pago',
      setUp: () => when(
        () => createSale(any()),
      ).thenAnswer((_) async => _sale('s1', 5000, reservationId: 'r1')),
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit.add('p1');
        await cubit.submit(reservationId: 'r1');
      },
      verify: (cubit) {
        final sent =
            verify(() => createSale(captureAny())).captured.single as NewSale;
        expect(sent.reservationId, 'r1');
        expect(sent.paymentMethod, isNull);
        expect(sent.quantities, {'p1': 1});
        expect(cubit.state.submit, SaleCartSubmit.done);
      },
    );

    blocTest<SaleCartCubit, SaleCartState>(
      'venta suelta: envía el método elegido',
      setUp: () => when(
        () => createSale(any()),
      ).thenAnswer((_) async => _sale('s1', 2500)),
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit
          ..add('p2')
          ..selectPaymentMethod('NEQUI');
        await cubit.submit();
      },
      verify: (_) {
        final sent =
            verify(() => createSale(captureAny())).captured.single as NewSale;
        expect(sent.paymentMethod, 'NEQUI');
      },
    );

    blocTest<SaleCartCubit, SaleCartState>(
      'muestra el mensaje de la API',
      setUp: () => when(() => createSale(any())).thenThrow(
        const ApiException(
          ApiErrorKind.conflict,
          message: 'Solo se pueden cargar consumos a reservas confirmadas',
        ),
      ),
      build: build,
      act: (cubit) async {
        await cubit.load();
        cubit.add('p1');
        await cubit.submit(reservationId: 'r1');
      },
      verify: (cubit) {
        expect(cubit.state.submit, SaleCartSubmit.failure);
        expect(cubit.state.message, contains('reservas confirmadas'));
      },
    );
  });

  group('SalesCubit', () {
    late _MockGetSales getSales;
    late _MockVoidSale voidSale;

    setUp(() {
      getSales = _MockGetSales();
      voidSale = _MockVoidSale();
      when(() => getSales(any())).thenAnswer(
        (_) async => [
          _sale('s1', 5000),
          _sale('s2', 75000, reservationId: 'r1'),
          _sale('s3', 9000, voided: true),
        ],
      );
    });

    SalesCubit build() => SalesCubit(
      getSales: getSales,
      voidSale: voidSale,
      now: () => DateTime(2026, 10, 28, 20),
    );

    blocTest<SalesCubit, SalesState>(
      'totales del día sin las anuladas',
      build: build,
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.total, 80000);
        expect(cubit.state.walkInTotal, 5000);
        expect(cubit.state.consumptionsTotal, 75000);
        expect(cubit.state.count, 2);
        verify(() => getSales(DateTime(2026, 10, 28))).called(1);
      },
    );

    blocTest<SalesCubit, SalesState>(
      'cambiar de día pide las ventas de ese día',
      build: build,
      act: (cubit) => cubit.shiftDay(-1),
      verify: (cubit) {
        expect(cubit.state.day, DateTime(2026, 10, 27));
        verify(() => getSales(DateTime(2026, 10, 27))).called(1);
      },
    );

    blocTest<SalesCubit, SalesState>(
      'anular reemplaza la venta y baja el total',
      setUp: () => when(
        () => voidSale(any()),
      ).thenAnswer((_) async => _sale('s1', 5000, voided: true)),
      build: build,
      act: (cubit) async {
        await cubit.load();
        expect(await cubit.voidSale('s1', 'Error'), isNull);
      },
      verify: (cubit) => expect(cubit.state.total, 75000),
    );
  });
}
