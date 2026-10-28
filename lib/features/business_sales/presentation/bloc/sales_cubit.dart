import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/sale.dart';
import '../../domain/usecases/sales_usecases.dart';

enum SalesLoad { loading, ready, failure }

final class SalesState extends Equatable {
  const SalesState({
    required this.day,
    this.load = SalesLoad.loading,
    this.sales = const [],
  });

  final DateTime day;
  final SalesLoad load;

  /// Ventas del día, más recientes primero (también las anuladas).
  final List<Sale> sales;

  Iterable<Sale> get _active => sales.where((s) => !s.isVoided);

  /// Todo lo vendido en el día (sin anuladas).
  int get total => _active.fold(0, (sum, s) => sum + s.total);

  /// Ventas sueltas: ya cobradas.
  int get walkInTotal =>
      _active.where((s) => s.isWalkIn).fold(0, (sum, s) => sum + s.total);

  /// Consumos cargados a reservas: se cobran con su saldo.
  int get consumptionsTotal => total - walkInTotal;

  int get count => _active.length;

  SalesState copyWith({DateTime? day, SalesLoad? load, List<Sale>? sales}) =>
      SalesState(
        day: day ?? this.day,
        load: load ?? this.load,
        sales: sales ?? this.sales,
      );

  @override
  List<Object?> get props => [day, load, sales];
}

/// Ventas de un día: sueltas y consumos de reservas.
class SalesCubit extends Cubit<SalesState> {
  SalesCubit({
    required GetSales getSales,
    required VoidSale voidSale,
    DateTime Function() now = DateTime.now,
  }) : _getSales = getSales,
       _voidSale = voidSale,
       super(SalesState(day: _dateOnly(now())));

  final GetSales _getSales;
  final VoidSale _voidSale;

  /// Descarta respuestas de un día que ya no se está viendo.
  int _generation = 0;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> load([DateTime? day]) async {
    final target = day == null ? state.day : _dateOnly(day);
    final generation = ++_generation;
    emit(state.copyWith(day: target, load: SalesLoad.loading));
    try {
      final sales = await _getSales(target);
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(load: SalesLoad.ready, sales: sales));
    } catch (_) {
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(load: SalesLoad.failure, sales: const []));
    }
  }

  Future<void> shiftDay(int days) =>
      load(DateTime(state.day.year, state.day.month, state.day.day + days));

  /// Devuelve el error para mostrar, o `null` si se anuló.
  Future<String?> voidSale(String id, String reason) async {
    try {
      final voided = await _voidSale((id: id, reason: reason));
      if (isClosed) return null;
      emit(
        state.copyWith(
          sales: [
            for (final sale in state.sales) sale.id == id ? voided : sale,
          ],
        ),
      );
      return null;
    } on ArgumentError catch (error) {
      return '${error.message}';
    } on ApiException catch (error) {
      return switch (error.kind) {
        ApiErrorKind.network =>
          'Sin conexión. Revisa tu internet e intenta de nuevo.',
        ApiErrorKind.forbidden ||
        ApiErrorKind.conflict ||
        ApiErrorKind.badRequest => error.message ?? 'No se pudo anular.',
        _ => 'No se pudo anular la venta. Intenta de nuevo.',
      };
    } catch (_) {
      return 'No se pudo anular la venta. Intenta de nuevo.';
    }
  }
}
