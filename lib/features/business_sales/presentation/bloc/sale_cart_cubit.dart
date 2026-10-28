import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/new_sale.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/sale.dart';
import '../../domain/usecases/sales_usecases.dart';

enum SaleCartLoad { loading, ready, failure }

enum SaleCartSubmit { idle, sending, done, failure }

final class SaleCartState extends Equatable {
  const SaleCartState({
    this.load = SaleCartLoad.loading,
    this.products = const [],
    this.quantities = const {},
    this.paymentMethod = 'EFECTIVO',
    this.submit = SaleCartSubmit.idle,
    this.message,
    this.sale,
  });

  final SaleCartLoad load;

  /// Productos activos, por nombre.
  final List<Product> products;

  /// Unidades elegidas por id de producto (solo las mayores a cero).
  final Map<String, int> quantities;

  /// `code` del método de pago de una venta suelta.
  final String paymentMethod;
  final SaleCartSubmit submit;

  /// Error para mostrar (validación o API).
  final String? message;

  /// Venta registrada.
  final Sale? sale;

  int quantityOf(String productId) => quantities[productId] ?? 0;

  int get units => quantities.values.fold(0, (sum, q) => sum + q);

  int get total =>
      products.fold(0, (sum, p) => sum + p.price * quantityOf(p.id));

  bool get isEmpty => quantities.isEmpty;

  SaleCartState copyWith({
    SaleCartLoad? load,
    List<Product>? products,
    Map<String, int>? quantities,
    String? paymentMethod,
    SaleCartSubmit? submit,
    String? Function()? message,
    Sale? sale,
  }) => SaleCartState(
    load: load ?? this.load,
    products: products ?? this.products,
    quantities: quantities ?? this.quantities,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    submit: submit ?? this.submit,
    message: message != null ? message() : this.message,
    sale: sale ?? this.sale,
  );

  @override
  List<Object?> get props => [
    load,
    products,
    quantities,
    paymentMethod,
    submit,
    message,
    sale,
  ];
}

/// Carrito para cargar consumos a una reserva ([reservationId]) o registrar
/// una venta suelta (sin reserva, se cobra con [SaleCartState.paymentMethod]).
class SaleCartCubit extends Cubit<SaleCartState> {
  SaleCartCubit({
    required GetProducts getProducts,
    required CreateSale createSale,
  }) : _getProducts = getProducts,
       _createSale = createSale,
       super(const SaleCartState());

  final GetProducts _getProducts;
  final CreateSale _createSale;

  Future<void> load() async {
    emit(state.copyWith(load: SaleCartLoad.loading));
    try {
      final products = await _getProducts(false);
      if (isClosed) return;
      emit(state.copyWith(load: SaleCartLoad.ready, products: products));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(load: SaleCartLoad.failure));
    }
  }

  void add(String productId) =>
      setQuantity(productId, state.quantityOf(productId) + 1);

  void remove(String productId) =>
      setQuantity(productId, state.quantityOf(productId) - 1);

  void setQuantity(String productId, int quantity) {
    if (state.submit == SaleCartSubmit.sending) return;
    final value = quantity.clamp(0, NewSale.maxQuantity);
    final quantities = Map.of(state.quantities);
    if (value == 0) {
      quantities.remove(productId);
    } else {
      quantities[productId] = value;
    }
    emit(state.copyWith(quantities: quantities, message: () => null));
  }

  void selectPaymentMethod(String code) =>
      emit(state.copyWith(paymentMethod: code));

  Future<void> submit({String? reservationId, String? reference}) async {
    if (state.submit == SaleCartSubmit.sending) return;
    emit(state.copyWith(submit: SaleCartSubmit.sending, message: () => null));
    try {
      final sale = await _createSale(
        NewSale(
          quantities: state.quantities,
          reservationId: reservationId,
          paymentMethod: reservationId == null ? state.paymentMethod : null,
          reference: reference,
        ),
      );
      if (isClosed) return;
      emit(state.copyWith(submit: SaleCartSubmit.done, sale: sale));
    } on ArgumentError catch (error) {
      _fail('${error.message}');
    } on ApiException catch (error) {
      _fail(switch (error.kind) {
        ApiErrorKind.network =>
          'Sin conexión. Revisa tu internet e intenta de nuevo.',
        ApiErrorKind.forbidden =>
          error.message ?? 'Tu plan no está activo: solo puedes consultar.',
        ApiErrorKind.badRequest ||
        ApiErrorKind.conflict ||
        ApiErrorKind.notFound =>
          error.message ?? 'No se pudo registrar la venta.',
        _ => 'No se pudo registrar la venta. Intenta de nuevo.',
      });
    } catch (_) {
      _fail('No se pudo registrar la venta. Intenta de nuevo.');
    }
  }

  void _fail(String message) {
    if (isClosed) return;
    emit(
      state.copyWith(submit: SaleCartSubmit.failure, message: () => message),
    );
  }
}
