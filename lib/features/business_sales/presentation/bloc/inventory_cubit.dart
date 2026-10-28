import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/cash_session.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/cash_usecases.dart';
import '../../domain/usecases/inventory_usecases.dart';

enum InventoryLoad { loading, ready, failure }

/// Filtro de la lista de inventario.
enum InventoryFilter { all, low, out, untracked }

final class InventoryState extends Equatable {
  const InventoryState({
    this.load = InventoryLoad.loading,
    this.overview = const InventoryOverview(),
    this.filter = InventoryFilter.all,
    this.query = '',
  });

  final InventoryLoad load;
  final InventoryOverview overview;
  final InventoryFilter filter;
  final String query;

  /// Productos que muestra la lista: los agotados y con stock bajo primero.
  List<Product> get visible {
    final text = query.trim().toLowerCase();
    final items = [
      for (final p in overview.items)
        if (switch (filter) {
              InventoryFilter.all => true,
              InventoryFilter.low => p.isLow && !p.isOut,
              InventoryFilter.out => p.isOut,
              InventoryFilter.untracked => !p.trackStock,
            } &&
            (text.isEmpty || p.name.toLowerCase().contains(text)))
          p,
    ];
    int rank(Product p) => p.isOut
        ? 0
        : p.isLow
        ? 1
        : p.trackStock
        ? 2
        : 3;
    // sort no es estable: el nombre desempata.
    return items..sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      return byRank != 0
          ? byRank
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  int countOf(InventoryFilter filter) => switch (filter) {
    InventoryFilter.all => overview.items.length,
    InventoryFilter.low => overview.low,
    InventoryFilter.out => overview.out,
    InventoryFilter.untracked => overview.items.length - overview.tracked,
  };

  InventoryState copyWith({
    InventoryLoad? load,
    InventoryOverview? overview,
    InventoryFilter? filter,
    String? query,
  }) => InventoryState(
    load: load ?? this.load,
    overview: overview ?? this.overview,
    filter: filter ?? this.filter,
    query: query ?? this.query,
  );

  @override
  List<Object?> get props => [load, overview, filter, query];
}

/// Inventario: existencias, entradas, ajustes e historial.
class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit({
    required GetInventory getInventory,
    required AddStockEntry addEntry,
    required AdjustStock adjustStock,
    required ConfigureStock configureStock,
    required GetStockMovements getMovements,
    required GetSuppliers getSuppliers,
    void Function(int alerts)? onAlerts,
  }) : _get = getInventory,
       _onAlerts = onAlerts,
       _addEntry = addEntry,
       _adjust = adjustStock,
       _configure = configureStock,
       _movements = getMovements,
       _suppliers = getSuppliers,
       super(const InventoryState());

  final GetInventory _get;
  final AddStockEntry _addEntry;
  final AdjustStock _adjust;
  final ConfigureStock _configure;
  final GetStockMovements _movements;
  final GetSuppliers _suppliers;

  /// Avisa cuántos productos están agotados o con stock bajo (menú).
  final void Function(int alerts)? _onAlerts;

  static const historyPageSize = 20;

  Future<void> load() async {
    try {
      final overview = await _get(const NoParams());
      if (isClosed) return;
      emit(state.copyWith(load: InventoryLoad.ready, overview: overview));
      _onAlerts?.call(overview.alerts);
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(load: InventoryLoad.failure));
    }
  }

  void filter(InventoryFilter filter) => emit(state.copyWith(filter: filter));

  void search(String query) => emit(state.copyWith(query: query));

  Future<String?> addEntry(StockEntryParams params) =>
      _apply(() => _addEntry(params));

  Future<String?> adjust(StockAdjustParams params) =>
      _apply(() => _adjust(params));

  Future<String?> configure(StockConfigParams params) =>
      _apply(() => _configure(params));

  Future<({List<StockMovement> items, int total})> movements(
    String? productId,
    int page,
  ) =>
      _movements((productId: productId, page: page, pageSize: historyPageSize));

  Future<List<Supplier>> suppliers() => _suppliers(false);

  /// Ejecuta la acción, recarga y devuelve el error para mostrar o `null`.
  Future<String?> _apply(Future<Object?> Function() request) async {
    try {
      await request();
    } on ArgumentError catch (error) {
      return '${error.message}';
    } on ApiException catch (error) {
      return switch (error.kind) {
        ApiErrorKind.network =>
          'Sin conexión. Revisa tu internet e intenta de nuevo.',
        ApiErrorKind.forbidden ||
        ApiErrorKind.conflict ||
        ApiErrorKind.badRequest ||
        ApiErrorKind.notFound =>
          error.message ?? 'No se pudo guardar. Intenta de nuevo.',
        _ => 'No se pudo guardar. Intenta de nuevo.',
      };
    } catch (_) {
      return 'No se pudo guardar. Intenta de nuevo.';
    }
    await load();
    return null;
  }
}
