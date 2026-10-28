import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/cash_session.dart';
import '../../domain/repositories/cash_repository.dart';
import '../../domain/usecases/cash_usecases.dart';

enum SuppliersLoad { loading, ready, failure }

final class SuppliersState extends Equatable {
  const SuppliersState({
    this.load = SuppliersLoad.loading,
    this.suppliers = const [],
  });

  final SuppliersLoad load;

  /// Todos (activos y desactivados), por nombre.
  final List<Supplier> suppliers;

  SuppliersState copyWith({SuppliersLoad? load, List<Supplier>? suppliers}) =>
      SuppliersState(
        load: load ?? this.load,
        suppliers: suppliers ?? this.suppliers,
      );

  @override
  List<Object?> get props => [load, suppliers];
}

/// Proveedores del negocio: registrar, editar y activar/desactivar.
class SuppliersCubit extends Cubit<SuppliersState> {
  SuppliersCubit({
    required GetSuppliers getSuppliers,
    required SaveSupplier saveSupplier,
    required SetSupplierActive setSupplierActive,
  }) : _get = getSuppliers,
       _save = saveSupplier,
       _setActive = setSupplierActive,
       super(const SuppliersState());

  final GetSuppliers _get;
  final SaveSupplier _save;
  final SetSupplierActive _setActive;

  Future<void> load() async {
    emit(state.copyWith(load: SuppliersLoad.loading));
    try {
      final suppliers = await _get(true);
      if (isClosed) return;
      emit(state.copyWith(load: SuppliersLoad.ready, suppliers: suppliers));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(load: SuppliersLoad.failure));
    }
  }

  /// Crea o edita. Devuelve el error para mostrar, o `null` si se guardó.
  Future<String?> save(SupplierDraft draft) => _apply(() => _save(draft));

  Future<String?> setActive(Supplier supplier, bool isActive) =>
      _apply(() => _setActive((id: supplier.id, isActive: isActive)));

  Future<String?> _apply(Future<Supplier> Function() request) async {
    try {
      final saved = await request();
      if (isClosed) return null;
      final suppliers = [
        for (final s in state.suppliers)
          if (s.id != saved.id) s,
        saved,
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      emit(state.copyWith(suppliers: suppliers));
      return null;
    } on ArgumentError catch (error) {
      return '${error.message}';
    } on ApiException catch (error) {
      return switch (error.kind) {
        ApiErrorKind.network =>
          'Sin conexión. Revisa tu internet e intenta de nuevo.',
        ApiErrorKind.forbidden ||
        ApiErrorKind.conflict ||
        ApiErrorKind.badRequest =>
          error.message ?? 'No se pudo guardar el proveedor.',
        _ => 'No se pudo guardar el proveedor. Intenta de nuevo.',
      };
    } catch (_) {
      return 'No se pudo guardar el proveedor. Intenta de nuevo.';
    }
  }
}
