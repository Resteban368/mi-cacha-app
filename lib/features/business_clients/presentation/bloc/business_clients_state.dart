import 'package:equatable/equatable.dart';

import '../../domain/entities/client_profile.dart';
import '../../domain/entities/customer_overview.dart';
import '../../domain/entities/customer_query.dart';
import '../../domain/entities/customers_page_result.dart';

enum ClientsStatus { initial, loading, success, failure }

/// Carga de la página siguiente (scroll infinito).
enum LoadMoreStatus { idle, loading, failure }

enum SaveCustomerStatus { idle, saving, success, failure }

class BusinessClientsState extends Equatable {
  const BusinessClientsState({
    this.status = ClientsStatus.initial,
    this.query = const CustomerQuery(),
    this.result,
    this.items,
    this.loadMore = LoadMoreStatus.idle,
    this.errorMessage,
    this.saveStatus = SaveCustomerStatus.idle,
    this.saveErrorMessage,
    this.lastSavedClient,
  });

  final ClientsStatus status;
  final CustomerQuery query;

  /// Última página recibida (total, página y resumen).
  final CustomersPageResult? result;

  /// Clientes de todas las páginas cargadas; `null` = los de [result].
  final List<ClientProfile>? items;
  final LoadMoreStatus loadMore;
  final String? errorMessage;
  final SaveCustomerStatus saveStatus;
  final String? saveErrorMessage;
  final ClientProfile? lastSavedClient;

  List<ClientProfile> get clients => items ?? result?.items ?? const [];
  CustomerOverview get overview => result?.overview ?? const CustomerOverview();
  int get totalClients => result?.total ?? clients.length;
  int get totalPages => result?.totalPages ?? 1;
  int get currentPage => result?.page ?? query.page;
  bool get hasNextPage => result?.hasNextPage ?? false;
  bool get hasPreviousPage => result?.hasPreviousPage ?? false;

  BusinessClientsState copyWith({
    ClientsStatus? status,
    CustomerQuery? query,
    CustomersPageResult? Function()? result,
    List<ClientProfile>? Function()? items,
    LoadMoreStatus? loadMore,
    String? Function()? errorMessage,
    SaveCustomerStatus? saveStatus,
    String? Function()? saveErrorMessage,
    ClientProfile? Function()? lastSavedClient,
  }) {
    return BusinessClientsState(
      status: status ?? this.status,
      query: query ?? this.query,
      result: result != null ? result() : this.result,
      items: items != null ? items() : this.items,
      loadMore: loadMore ?? this.loadMore,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      saveStatus: saveStatus ?? this.saveStatus,
      saveErrorMessage: saveErrorMessage != null
          ? saveErrorMessage()
          : this.saveErrorMessage,
      lastSavedClient: lastSavedClient != null
          ? lastSavedClient()
          : this.lastSavedClient,
    );
  }

  @override
  List<Object?> get props => [
    status,
    query,
    result,
    items,
    loadMore,
    errorMessage,
    saveStatus,
    saveErrorMessage,
    lastSavedClient,
  ];
}
