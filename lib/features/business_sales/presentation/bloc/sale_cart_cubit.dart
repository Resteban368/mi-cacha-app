import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../business_reservations/domain/entities/reservation.dart';
import '../../../business_reservations/domain/usecases/get_day_reservations.dart';
import '../../domain/entities/new_sale.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/sale.dart';
import '../../domain/usecases/sales_usecases.dart';

enum SaleCartLoad { loading, ready, failure }

enum SaleCartSubmit { idle, sending, done, failure }

/// Reservas de hoy para asociarles la venta (se cargan al pedirlas).
enum LinkLoad { idle, loading, ready, failure }

final class SaleCartState extends Equatable {
  const SaleCartState({
    this.load = SaleCartLoad.loading,
    this.products = const [],
    this.quantities = const {},
    this.paymentMethod = 'EFECTIVO',
    this.chargeNow = false,
    this.query = '',
    this.category,
    this.note = '',
    this.linkToReservation = false,
    this.linkLoad = LinkLoad.idle,
    this.reservations = const [],
    this.linked,
    this.submit = SaleCartSubmit.idle,
    this.message,
    this.sale,
  });

  final SaleCartLoad load;

  /// Unidades disponibles para vender de [product]: su stock si lo
  /// controla, `null` (sin límite) si no.
  int? availableOf(Product product) =>
      product.trackStock ? (product.stock < 0 ? 0 : product.stock) : null;

  /// Productos activos, por nombre.
  final List<Product> products;

  /// Unidades elegidas por id de producto (solo las mayores a cero).
  final Map<String, int> quantities;

  /// `code` del método de pago (venta suelta o consumo cobrado ya).
  final String paymentMethod;

  /// En un consumo de reserva: cobrarlo ya en vez de sumarlo al saldo.
  final bool chargeNow;

  /// Búsqueda por nombre y filtro por categoría de la cuadrícula.
  final String query;
  final ProductCategory? category;
  final String note;

  /// Venta nueva: asociarla a una reserva en vez de dejarla suelta.
  final bool linkToReservation;
  final LinkLoad linkLoad;

  /// Reservas de hoy a las que se les pueden cargar consumos.
  final List<Reservation> reservations;

  /// Reserva elegida para la venta (solo con [linkToReservation]).
  final Reservation? linked;
  final SaleCartSubmit submit;

  /// Error para mostrar (validación o API).
  final String? message;

  /// Venta registrada.
  final Sale? sale;

  int quantityOf(String productId) => quantities[productId] ?? 0;

  /// Productos que muestra la cuadrícula (mantiene el orden de más vendidos).
  List<Product> get visibleProducts {
    final text = query.trim().toLowerCase();
    return [
      for (final p in products)
        if ((category == null || p.category == category) &&
            (text.isEmpty || p.name.toLowerCase().contains(text)))
          p,
    ];
  }

  /// Categorías presentes en el catálogo, con cuántos productos tiene cada una.
  Map<ProductCategory, int> get categoryCounts {
    final counts = <ProductCategory, int>{};
    for (final p in products) {
      counts[p.category] = (counts[p.category] ?? 0) + 1;
    }
    return {
      for (final c in ProductCategory.values)
        if (counts.containsKey(c)) c: counts[c]!,
    };
  }

  int get units => quantities.values.fold(0, (sum, q) => sum + q);

  int get total =>
      products.fold(0, (sum, p) => sum + p.price * quantityOf(p.id));

  bool get isEmpty => quantities.isEmpty;

  SaleCartState copyWith({
    SaleCartLoad? load,
    List<Product>? products,
    Map<String, int>? quantities,
    String? paymentMethod,
    bool? chargeNow,
    String? query,
    ProductCategory? Function()? category,
    String? note,
    bool? linkToReservation,
    LinkLoad? linkLoad,
    List<Reservation>? reservations,
    Reservation? Function()? linked,
    SaleCartSubmit? submit,
    String? Function()? message,
    Sale? sale,
  }) => SaleCartState(
    load: load ?? this.load,
    products: products ?? this.products,
    quantities: quantities ?? this.quantities,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    chargeNow: chargeNow ?? this.chargeNow,
    query: query ?? this.query,
    category: category != null ? category() : this.category,
    note: note ?? this.note,
    linkToReservation: linkToReservation ?? this.linkToReservation,
    linkLoad: linkLoad ?? this.linkLoad,
    reservations: reservations ?? this.reservations,
    linked: linked != null ? linked() : this.linked,
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
    chargeNow,
    query,
    category,
    note,
    linkToReservation,
    linkLoad,
    reservations,
    linked,
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
    GetDayReservations? getDayReservations,
    DateTime Function() now = DateTime.now,
  }) : _getProducts = getProducts,
       _createSale = createSale,
       _getDayReservations = getDayReservations,
       _now = now,
       super(const SaleCartState());

  final GetProducts _getProducts;
  final CreateSale _createSale;
  final GetDayReservations? _getDayReservations;
  final DateTime Function() _now;

  /// Elige el destino de una venta nueva: suelta o a una reserva de hoy.
  Future<void> setLinkToReservation(bool link) async {
    emit(
      state.copyWith(
        linkToReservation: link,
        // Una venta suelta siempre se cobra; un consumo, según el modo.
        chargeNow: link ? state.chargeNow : false,
        message: () => null,
      ),
    );
    if (link && state.linkLoad != LinkLoad.ready) await loadReservations();
  }

  Future<void> loadReservations() async {
    final getDay = _getDayReservations;
    if (getDay == null) return;
    emit(state.copyWith(linkLoad: LinkLoad.loading));
    try {
      final all = await getDay(_now());
      if (isClosed) return;
      emit(
        state.copyWith(
          linkLoad: LinkLoad.ready,
          reservations: [
            for (final r in all)
              if (r.acceptsConsumptions) r,
          ],
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(linkLoad: LinkLoad.failure));
    }
  }

  void linkReservation(Reservation? reservation) =>
      emit(state.copyWith(linked: () => reservation, message: () => null));

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
    var max = NewSale.maxQuantity;
    for (final p in state.products) {
      if (p.id != productId) continue;
      if (state.availableOf(p) case final available?) {
        if (available < max) max = available;
      }
    }
    final value = quantity.clamp(0, max);
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

  void setChargeNow(bool chargeNow) =>
      emit(state.copyWith(chargeNow: chargeNow));

  void search(String query) => emit(state.copyWith(query: query));

  void filterCategory(ProductCategory? category) =>
      emit(state.copyWith(category: () => category));

  void setNote(String note) => emit(state.copyWith(note: note.trim()));

  /// Vacía el carrito.
  void clear() {
    if (state.submit == SaleCartSubmit.sending) return;
    emit(state.copyWith(quantities: const {}, message: () => null));
  }

  Future<void> submit({String? reservationId, String? reference}) async {
    if (state.submit == SaleCartSubmit.sending) return;
    // Venta nueva asociada a una reserva elegida en el carrito.
    reservationId ??= state.linkToReservation ? state.linked?.id : null;
    if (state.linkToReservation && reservationId == null) {
      _fail('Elige la reserva a la que se asocia la venta.');
      return;
    }
    emit(state.copyWith(submit: SaleCartSubmit.sending, message: () => null));
    try {
      final sale = await _createSale(
        NewSale(
          quantities: state.quantities,
          reservationId: reservationId,
          // Venta suelta o consumo cobrado ya: lleva su pago.
          paymentMethod: reservationId == null || state.chargeNow
              ? state.paymentMethod
              : null,
          reference: reference,
          note: state.note.isEmpty ? null : state.note,
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
