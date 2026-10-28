import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/sales_usecases.dart';

enum ProductsLoad { loading, ready, failure }

final class ProductsState extends Equatable {
  const ProductsState({
    this.load = ProductsLoad.loading,
    this.products = const [],
  });

  final ProductsLoad load;

  /// Todos los productos (activos y desactivados), por nombre.
  final List<Product> products;

  ProductsState copyWith({ProductsLoad? load, List<Product>? products}) =>
      ProductsState(
        load: load ?? this.load,
        products: products ?? this.products,
      );

  @override
  List<Object?> get props => [load, products];
}

/// Catálogo de productos del negocio: crear, editar y activar/desactivar.
class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit({
    required GetProducts getProducts,
    required SaveProduct saveProduct,
    required SetProductActive setProductActive,
  }) : _getProducts = getProducts,
       _save = saveProduct,
       _setActive = setProductActive,
       super(const ProductsState());

  final GetProducts _getProducts;
  final SaveProduct _save;
  final SetProductActive _setActive;

  Future<void> load() async {
    emit(state.copyWith(load: ProductsLoad.loading));
    try {
      final products = await _getProducts(true);
      if (isClosed) return;
      emit(state.copyWith(load: ProductsLoad.ready, products: products));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(load: ProductsLoad.failure));
    }
  }

  /// Crea o edita. Devuelve el error para mostrar, o `null` si se guardó.
  Future<String?> save(ProductDraft draft) => _apply(() => _save(draft));

  Future<String?> setActive(Product product, bool isActive) =>
      _apply(() => _setActive((id: product.id, isActive: isActive)));

  Future<String?> _apply(Future<Product> Function() request) async {
    try {
      final saved = await request();
      if (isClosed) return null;
      final products = [
        for (final p in state.products)
          if (p.id != saved.id) p,
        saved,
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      emit(state.copyWith(products: products));
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
          error.message ?? 'No se pudo guardar el producto.',
        _ => 'No se pudo guardar el producto. Intenta de nuevo.',
      };
    } catch (_) {
      return 'No se pudo guardar el producto. Intenta de nuevo.';
    }
  }
}
