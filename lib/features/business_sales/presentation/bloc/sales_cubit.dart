import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/sale.dart';
import '../../domain/usecases/sales_usecases.dart';

enum SalesLoad { loading, ready, failure }

/// Pestañas de la lista de ventas.
enum SalesTab { all, walkIn, consumptions, voided }

/// Filtro por método: un `code` del catálogo o los consumos sin cobrar.
const chargedToReservation = 'RESERVA';

final class SalesState extends Equatable {
  const SalesState({
    required this.day,
    this.load = SalesLoad.loading,
    this.sales = const [],
    this.tab = SalesTab.all,
    this.query = '',
    this.method,
  });

  final DateTime day;
  final SalesLoad load;

  /// Ventas del día, más recientes primero (también las anuladas).
  final List<Sale> sales;
  final SalesTab tab;
  final String query;

  /// `code` del método, [chargedToReservation] o `null` (todos).
  final String? method;

  Iterable<Sale> get _active => sales.where((s) => !s.isVoided);

  /// Todo lo vendido en el día (sin anuladas).
  int get total => _active.fold(0, (sum, s) => sum + s.total);

  /// Ventas sueltas: ya cobradas.
  int get walkInTotal =>
      _active.where((s) => s.isWalkIn).fold(0, (sum, s) => sum + s.total);

  /// Consumos de reservas (cargados al saldo o cobrados ya).
  int get consumptionsTotal => total - walkInTotal;

  int get count => _active.length;

  Iterable<Sale> get _voided => sales.where((s) => s.isVoided);

  int get voidedCount => _voided.length;
  int get voidedTotal => _voided.fold(0, (sum, s) => sum + s.total);

  /// Arqueo: lo cobrado por cada método (`code` → monto), de mayor a menor.
  /// Los consumos cargados al saldo no entran: aún no se han cobrado.
  List<MapEntry<String, int>> get byMethod {
    final totals = <String, int>{};
    for (final s in _active) {
      if (s.paymentMethod case final code?) {
        totals[code] = (totals[code] ?? 0) + s.total;
      }
    }
    return totals.entries.toList()..sort((a, b) => b.value - a.value);
  }

  /// Consumos cargados al saldo de su reserva (por cobrar con la reserva).
  int get chargedToReservations => _active
      .where((s) => !s.isWalkIn && !s.isPaid)
      .fold(0, (sum, s) => sum + s.total);

  int countOf(SalesTab tab) => sales.where((s) => _inTab(s, tab)).length;

  /// Métodos presentes en el día (para el filtro).
  List<String> get methods =>
      {for (final s in sales) ?s.paymentMethod}.toList();

  static bool _inTab(Sale s, SalesTab tab) => switch (tab) {
    SalesTab.all => true,
    SalesTab.walkIn => s.isWalkIn && !s.isVoided,
    SalesTab.consumptions => !s.isWalkIn && !s.isVoided,
    SalesTab.voided => s.isVoided,
  };

  /// Ventas que muestra la lista con la pestaña, búsqueda y método elegidos.
  List<Sale> get visible {
    final text = query.trim().toLowerCase();
    return [
      for (final s in sales)
        if (_inTab(s, tab) &&
            switch (method) {
              null => true,
              chargedToReservation => !s.isWalkIn && !s.isPaid && !s.isVoided,
              final code => s.paymentMethod == code,
            } &&
            (text.isEmpty ||
                s.itemsLabel.toLowerCase().contains(text) ||
                (s.customerName?.toLowerCase().contains(text) ?? false)))
          s,
    ];
  }

  SalesState copyWith({
    DateTime? day,
    SalesLoad? load,
    List<Sale>? sales,
    SalesTab? tab,
    String? query,
    String? Function()? method,
  }) => SalesState(
    day: day ?? this.day,
    load: load ?? this.load,
    sales: sales ?? this.sales,
    tab: tab ?? this.tab,
    query: query ?? this.query,
    method: method != null ? method() : this.method,
  );

  @override
  List<Object?> get props => [day, load, sales, tab, query, method];
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

  void selectTab(SalesTab tab) => emit(state.copyWith(tab: tab));

  void search(String query) => emit(state.copyWith(query: query));

  void filterMethod(String? method) =>
      emit(state.copyWith(method: () => method));

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
