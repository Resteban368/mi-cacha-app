part of 'new_reservation_bloc.dart';

enum NewReservationLoad { loading, ready, failure }

enum AvailabilityLoad { idle, loading, ready, failure }

enum CustomerSearchStatus { idle, loading, ready, failure }

enum NewReservationSubmit { idle, submitting, success, failure }

final class NewReservationState extends Equatable {
  const NewReservationState({
    required this.day,
    this.load = NewReservationLoad.loading,
    this.courts = const [],
    this.paymentMethods = const [],
    this.court,
    this.availabilityLoad = AvailabilityLoad.idle,
    this.availability,
    this.startIndex,
    this.slotCount = 1,
    this.customerQuery = '',
    this.customerResults = const [],
    this.customerSearch = CustomerSearchStatus.idle,
    this.customer,
    this.submit = NewReservationSubmit.idle,
    this.created,
    this.failure,
    this.failureMessage,
  });

  final NewReservationLoad load;

  /// Primero las reservables; las demás se muestran deshabilitadas.
  final List<Court> courts;

  /// Métodos de pago activos del catálogo, en su orden.
  final List<CatalogPaymentMethod> paymentMethods;
  final Court? court;

  /// Día local elegido (mínimo hoy).
  final DateTime day;

  final AvailabilityLoad availabilityLoad;
  final Availability? availability;

  /// Turno inicial elegido (índice en `availability.slots`).
  final int? startIndex;
  final int slotCount;

  final String customerQuery;
  final List<Customer> customerResults;
  final CustomerSearchStatus customerSearch;

  /// Cliente existente elegido (si no, se crea uno nuevo).
  final Customer? customer;

  final NewReservationSubmit submit;
  final Reservation? created;
  final ReservationFailure? failure;
  final String? failureMessage;

  bool get hasBookableCourts => courts.any((c) => c.isBookable);

  /// Turnos libres seguidos desde el elegido (tope `maxSlots`).
  int get maxSlotCount {
    final index = startIndex;
    if (index == null) return 0;
    return availability?.consecutiveFrom(index) ?? 0;
  }

  List<Slot> get selectedSlots {
    final index = startIndex;
    final slots = availability?.slots;
    if (index == null || slots == null) return const [];
    return slots.skip(index).take(slotCount).toList();
  }

  /// Suma estimada de los turnos elegidos (la API recalcula el valor).
  int? get subtotal {
    final index = startIndex;
    if (index == null) return null;
    return availability?.priceFor(index, slotCount);
  }

  NewReservationState copyWith({
    NewReservationLoad? load,
    List<Court>? courts,
    List<CatalogPaymentMethod>? paymentMethods,
    Court? Function()? court,
    DateTime? day,
    AvailabilityLoad? availabilityLoad,
    Availability? Function()? availability,
    int? Function()? startIndex,
    int? slotCount,
    String? customerQuery,
    List<Customer>? customerResults,
    CustomerSearchStatus? customerSearch,
    Customer? Function()? customer,
    NewReservationSubmit? submit,
    Reservation? Function()? created,
    ReservationFailure? Function()? failure,
    String? Function()? failureMessage,
  }) => NewReservationState(
    load: load ?? this.load,
    courts: courts ?? this.courts,
    paymentMethods: paymentMethods ?? this.paymentMethods,
    court: court != null ? court() : this.court,
    day: day ?? this.day,
    availabilityLoad: availabilityLoad ?? this.availabilityLoad,
    availability: availability != null ? availability() : this.availability,
    startIndex: startIndex != null ? startIndex() : this.startIndex,
    slotCount: slotCount ?? this.slotCount,
    customerQuery: customerQuery ?? this.customerQuery,
    customerResults: customerResults ?? this.customerResults,
    customerSearch: customerSearch ?? this.customerSearch,
    customer: customer != null ? customer() : this.customer,
    submit: submit ?? this.submit,
    created: created != null ? created() : this.created,
    failure: failure != null ? failure() : this.failure,
    failureMessage: failureMessage != null
        ? failureMessage()
        : this.failureMessage,
  );

  @override
  List<Object?> get props => [
    load,
    courts,
    paymentMethods,
    court,
    day,
    availabilityLoad,
    availability,
    startIndex,
    slotCount,
    customerQuery,
    customerResults,
    customerSearch,
    customer,
    submit,
    created,
    failure,
    failureMessage,
  ];
}
