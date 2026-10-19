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
    this.sport,
    this.focusCourtId,
    this.availabilityLoad = AvailabilityLoad.idle,
    this.availability,
    this.anyCourt = false,
    this.selectedCourtId,
    this.selectedStart,
    this.slotCount = 1,
    this.extraCourtIds = const [],
    this.anyCourtCount = 1,
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

  /// Todas las canchas del negocio (para los deportes y las ocultas).
  final List<Court> courts;

  /// Métodos de pago activos del catálogo, en su orden.
  final List<CatalogPaymentMethod> paymentMethods;

  /// Deporte elegido (obligatorio para ver turnos).
  final Sport? sport;

  /// Cancha cuya tarjeta se resalta (al venir desde la agenda).
  final String? focusCourtId;

  /// Día local elegido (mínimo hoy).
  final DateTime day;

  final AvailabilityLoad availabilityLoad;
  final SportAvailability? availability;

  /// "Cualquier cancha libre a esa hora".
  final bool anyCourt;

  /// Cancha del turno elegido (sin uso con [anyCourt]).
  final String? selectedCourtId;

  /// Inicio (hora local) del turno elegido.
  final DateTime? selectedStart;
  final int slotCount;

  /// Otras canchas elegidas en la misma franja (sin uso con [anyCourt]).
  final List<String> extraCourtIds;

  /// Con [anyCourt]: cuántas canchas libres a la vez.
  final int anyCourtCount;

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

  /// Deportes con al menos una cancha reservable, en orden fijo.
  List<Sport> get sports => [
    for (final sport in Sport.values)
      if (courts.any((c) => c.sport == sport && c.isBookable)) sport,
  ];

  /// Canchas del deporte que no aparecen (inactivas o sin sus fotos).
  int get hiddenCourtCount =>
      courts.where((c) => c.sport == sport && !c.isBookable).length;

  /// La cancha del turno elegido; con [anyCourt], la que asignaría la API.
  CourtSlots? get selectedCourt {
    final start = selectedStart;
    final availability = this.availability;
    if (start == null || availability == null) return null;
    return anyCourt
        ? availability.firstFreeCourt(start, slotCount)
        : availability.courtById(selectedCourtId);
  }

  int? get _startIndex {
    final start = selectedStart;
    final court = selectedCourt;
    if (start == null || court == null) return null;
    final index = court.indexOf(start);
    return index < 0 ? null : index;
  }

  /// Todas las canchas de la reserva: la elegida y las sumadas; con
  /// [anyCourt], las que asignaría la API.
  List<CourtSlots> get selectedCourts {
    final start = selectedStart;
    final availability = this.availability;
    if (start == null || availability == null) return const [];
    if (anyCourt) {
      return availability
          .courtsFreeAt(start, slotCount)
          .take(anyCourtCount)
          .toList();
    }
    return [
      for (final id in [selectedCourtId, ...extraCourtIds])
        ?availability.courtById(id),
    ];
  }

  /// Turnos libres seguidos desde el elegido (tope `maxSlots`) en todas las
  /// canchas de la reserva; con [anyCourt], en [anyCourtCount] canchas.
  int get maxSlotCount {
    final start = selectedStart;
    final availability = this.availability;
    if (start == null || availability == null) return 0;
    if (anyCourt) return availability.reachFor(start, anyCourtCount);
    final courts = selectedCourts;
    if (courts.isEmpty) return 0;
    return courts
        .map((c) => c.consecutiveFrom(c.indexOf(start), availability.maxSlots))
        .reduce((a, b) => a < b ? a : b);
  }

  /// Otras canchas que se pueden sumar: mismo turno y libres en la franja.
  List<CourtSlots> get addableCourts {
    final start = selectedStart;
    final availability = this.availability;
    final primary = selectedCourt;
    if (anyCourt || start == null || availability == null || primary == null) {
      return const [];
    }
    if (1 + extraCourtIds.length >= NewReservation.maxCourts) return const [];
    return [
      for (final c in availability.courts)
        if (c.court.id != primary.court.id &&
            !extraCourtIds.contains(c.court.id) &&
            c.court.slotDuration == primary.court.slotDuration &&
            c.consecutiveFrom(c.indexOf(start), availability.maxSlots) >=
                slotCount)
          c,
    ];
  }

  /// Con [anyCourt]: cuántas canchas libres hay a la vez en la franja (tope
  /// [NewReservation.maxCourts]).
  int get anyCourtCountMax {
    final start = selectedStart;
    final availability = this.availability;
    if (!anyCourt || start == null || availability == null) return 1;
    final free = availability.courtsFreeAt(start, slotCount).length;
    return free.clamp(1, NewReservation.maxCourts);
  }

  List<Slot> get selectedSlots {
    final index = _startIndex;
    final court = selectedCourt;
    if (index == null || court == null) return const [];
    return court.slots.skip(index).take(slotCount).toList();
  }

  /// Suma estimada de los turnos elegidos en todas las canchas (la API
  /// recalcula el valor).
  int? get subtotal {
    final start = selectedStart;
    if (_startIndex == null || start == null) return null;
    final courts = selectedCourts;
    if (courts.isEmpty) return null;
    return courts.fold<int>(
      0,
      (sum, c) => sum + c.priceFor(c.indexOf(start), slotCount),
    );
  }

  /// Lo mínimo que puede valer la reserva: con [anyCourt] la API puede
  /// asignar canchas más baratas que las estimadas.
  int? get lowestSubtotal {
    final start = selectedStart;
    final availability = this.availability;
    if (!anyCourt || start == null || availability == null) return subtotal;
    if (anyCourtCount == 1) return availability.lowestPriceAt(start, slotCount);
    final prices = [
      for (final c in availability.courtsFreeAt(start, slotCount))
        c.priceFor(c.indexOf(start), slotCount),
    ]..sort();
    if (prices.length < anyCourtCount) return null;
    return prices.take(anyCourtCount).fold<int>(0, (a, b) => a + b);
  }

  /// El valor puede cambiar según la cancha que asigne la API.
  bool get priceMayVary {
    final lowest = lowestSubtotal;
    return anyCourt && lowest != null && lowest != subtotal;
  }

  NewReservationState copyWith({
    NewReservationLoad? load,
    List<Court>? courts,
    List<CatalogPaymentMethod>? paymentMethods,
    Sport? Function()? sport,
    String? Function()? focusCourtId,
    DateTime? day,
    AvailabilityLoad? availabilityLoad,
    SportAvailability? Function()? availability,
    bool? anyCourt,
    String? Function()? selectedCourtId,
    DateTime? Function()? selectedStart,
    int? slotCount,
    List<String>? extraCourtIds,
    int? anyCourtCount,
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
    sport: sport != null ? sport() : this.sport,
    focusCourtId: focusCourtId != null ? focusCourtId() : this.focusCourtId,
    day: day ?? this.day,
    availabilityLoad: availabilityLoad ?? this.availabilityLoad,
    availability: availability != null ? availability() : this.availability,
    anyCourt: anyCourt ?? this.anyCourt,
    selectedCourtId: selectedCourtId != null
        ? selectedCourtId()
        : this.selectedCourtId,
    selectedStart: selectedStart != null ? selectedStart() : this.selectedStart,
    slotCount: slotCount ?? this.slotCount,
    extraCourtIds: extraCourtIds ?? this.extraCourtIds,
    anyCourtCount: anyCourtCount ?? this.anyCourtCount,
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
    sport,
    focusCourtId,
    day,
    availabilityLoad,
    availability,
    anyCourt,
    selectedCourtId,
    selectedStart,
    slotCount,
    extraCourtIds,
    anyCourtCount,
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
