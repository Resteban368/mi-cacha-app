part of 'new_payment_bloc.dart';

enum NewPaymentStatus { initial, submitting, success, failure }

enum EntitySearchStatus { idle, loading, ready, failure }

final class NewPaymentState extends Equatable {
  const NewPaymentState({
    this.status = NewPaymentStatus.initial,
    this.created,
    this.targetMode = PaymentTargetMode.customer,
    this.customerSearchStatus = EntitySearchStatus.idle,
    this.customerResults = const [],
    this.customerPage = 0,
    this.customerHasMore = false,
    this.customerLoadMoreStatus = EntitySearchStatus.idle,
    this.selectedCustomer,
    this.customerReservationsStatus = EntitySearchStatus.idle,
    this.customerReservations = const [],
    this.reservationSearchStatus = EntitySearchStatus.idle,
    this.reservationResults = const [],
    this.selectedReservation,
  });

  final NewPaymentStatus status;
  final Payment? created;
  final PaymentTargetMode targetMode;

  final EntitySearchStatus customerSearchStatus;

  /// Clientes de todas las páginas cargadas (de 20 en 20).
  final List<Customer> customerResults;

  /// Última página de clientes cargada (0 = ninguna).
  final int customerPage;
  final bool customerHasMore;

  /// Carga de la página siguiente (scroll infinito).
  final EntitySearchStatus customerLoadMoreStatus;
  final Customer? selectedCustomer;

  final EntitySearchStatus customerReservationsStatus;
  final List<Reservation> customerReservations;

  final EntitySearchStatus reservationSearchStatus;
  final List<Reservation> reservationResults;
  final Reservation? selectedReservation;

  bool get isSubmitting => status == NewPaymentStatus.submitting;

  NewPaymentState copyWith({
    NewPaymentStatus? status,
    Payment? Function()? created,
    PaymentTargetMode? targetMode,
    EntitySearchStatus? customerSearchStatus,
    List<Customer>? customerResults,
    int? customerPage,
    bool? customerHasMore,
    EntitySearchStatus? customerLoadMoreStatus,
    Customer? Function()? selectedCustomer,
    EntitySearchStatus? customerReservationsStatus,
    List<Reservation>? customerReservations,
    EntitySearchStatus? reservationSearchStatus,
    List<Reservation>? reservationResults,
    Reservation? Function()? selectedReservation,
  }) {
    return NewPaymentState(
      status: status ?? this.status,
      created: created != null ? created() : this.created,
      targetMode: targetMode ?? this.targetMode,
      customerSearchStatus: customerSearchStatus ?? this.customerSearchStatus,
      customerResults: customerResults ?? this.customerResults,
      customerPage: customerPage ?? this.customerPage,
      customerHasMore: customerHasMore ?? this.customerHasMore,
      customerLoadMoreStatus:
          customerLoadMoreStatus ?? this.customerLoadMoreStatus,
      selectedCustomer: selectedCustomer != null
          ? selectedCustomer()
          : this.selectedCustomer,
      customerReservationsStatus:
          customerReservationsStatus ?? this.customerReservationsStatus,
      customerReservations: customerReservations ?? this.customerReservations,
      reservationSearchStatus:
          reservationSearchStatus ?? this.reservationSearchStatus,
      reservationResults: reservationResults ?? this.reservationResults,
      selectedReservation: selectedReservation != null
          ? selectedReservation()
          : this.selectedReservation,
    );
  }

  @override
  List<Object?> get props => [
    status,
    created,
    targetMode,
    customerSearchStatus,
    customerResults,
    customerPage,
    customerHasMore,
    customerLoadMoreStatus,
    selectedCustomer,
    customerReservationsStatus,
    customerReservations,
    reservationSearchStatus,
    reservationResults,
    selectedReservation,
  ];
}
