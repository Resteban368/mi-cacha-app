import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/domain/entities/sport.dart';
import 'package:mi_cancha/features/business_reservations/domain/entities/reservation.dart';
import 'package:mi_cancha/features/business_sales/domain/entities/new_sale.dart';
import 'package:mi_cancha/features/business_sales/domain/repositories/sales_repository.dart';
import 'package:mi_cancha/features/business_sales/domain/usecases/sales_usecases.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements SalesRepository {}

Reservation _reservation({
  int total = 60000,
  int consumptions = 0,
  int paid = 0,
  ReservationGroup? group,
  ReservationStatus status = ReservationStatus.confirmed,
}) => Reservation(
  id: 'r1',
  courtName: 'Cancha 1',
  sport: Sport.futbol,
  start: DateTime(2026, 10, 28, 18),
  end: DateTime(2026, 10, 28, 19),
  customerName: 'Juan',
  phone: '300',
  totalPrice: total,
  consumptionsTotal: consumptions,
  amountPaid: paid,
  status: status,
  group: group,
);

void main() {
  group('Reservation con consumos', () {
    test('el saldo suma cancha y consumos', () {
      final r = _reservation(consumptions: 75000, paid: 60000);
      expect(r.displayTotal, 135000);
      expect(r.displayBalance, 75000);
      expect(r.isFullyPaid, isFalse);
    });

    test('en un grupo usa los consumos de todas las canchas', () {
      final r = _reservation(
        consumptions: 10000,
        group: const ReservationGroup(
          id: 'g1',
          courts: [],
          totalPrice: 120000,
          consumptionsTotal: 30000,
          amountPaid: 120000,
        ),
      );
      expect(r.displayTotal, 150000);
      expect(r.displayConsumptions, 30000);
      expect(r.displayBalance, 30000);
    });

    test('solo confirmadas y jugadas aceptan consumos', () {
      expect(_reservation().acceptsConsumptions, isTrue);
      expect(
        _reservation(status: ReservationStatus.completed).acceptsConsumptions,
        isTrue,
      );
      expect(
        _reservation(status: ReservationStatus.cancelled).acceptsConsumptions,
        isFalse,
      );
      expect(
        _reservation(status: ReservationStatus.noShow).acceptsConsumptions,
        isFalse,
      );
    });
  });

  group('CreateSale', () {
    late _MockRepository repository;

    setUpAll(() => registerFallbackValue(const NewSale(quantities: {})));
    setUp(() => repository = _MockRepository());

    test('pide al menos un producto', () {
      expect(
        () => CreateSale(repository)(
          const NewSale(quantities: {'p1': 0}, reservationId: 'r1'),
        ),
        throwsArgumentError,
      );
      verifyNever(() => repository.createSale(any()));
    });

    test('una venta suelta necesita el método de pago', () {
      expect(
        () => CreateSale(repository)(const NewSale(quantities: {'p1': 2})),
        throwsArgumentError,
      );
    });

    test('limita las unidades por producto', () {
      expect(
        () => CreateSale(repository)(
          const NewSale(quantities: {'p1': 1000}, reservationId: 'r1'),
        ),
        throwsArgumentError,
      );
    });
  });

  test('SaveProduct valida nombre y precio', () {
    final save = SaveProduct(_MockRepository());
    expect(() => save((id: null, name: ' ', price: 1000)), throwsArgumentError);
    expect(
      () => save((id: null, name: 'Agua', price: -1)),
      throwsArgumentError,
    );
  });
}
