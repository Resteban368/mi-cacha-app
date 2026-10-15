import 'package:equatable/equatable.dart';

import '../../domain/entities/client_profile.dart';
import '../../domain/entities/customer_overview.dart';
import '../../domain/entities/customer_query.dart';
import '../../domain/entities/customers_page_result.dart';

enum ClientsStatus {
  initial,
  loading,
  success,
  failure,
}

enum SaveCustomerStatus {
  idle,
  saving,
  success,
  failure,
}

class BusinessClientsState extends Equatable {
  const BusinessClientsState({
    this.status = ClientsStatus.initial,
    this.query = const CustomerQuery(),
    this.result,
    this.errorMessage,
    this.saveStatus = SaveCustomerStatus.idle,
    this.saveErrorMessage,
    this.lastSavedClient,
  });

  final ClientsStatus status;
  final CustomerQuery query;
  final CustomersPageResult? result;
  final String? errorMessage;
  final SaveCustomerStatus saveStatus;
  final String? saveErrorMessage;
  final ClientProfile? lastSavedClient;

  List<ClientProfile> get clients => result?.items ?? const [];
  CustomerOverview get overview =>
      result?.overview ?? const CustomerOverview();
  int get totalClients => result?.total ?? clients.length;
  int get totalPages => result?.totalPages ?? 1;
  int get currentPage => result?.page ?? query.page;
  bool get hasNextPage => result?.hasNextPage ?? false;
  bool get hasPreviousPage => result?.hasPreviousPage ?? false;

  BusinessClientsState copyWith({
    ClientsStatus? status,
    CustomerQuery? query,
    CustomersPageResult? Function()? result,
    String? Function()? errorMessage,
    SaveCustomerStatus? saveStatus,
    String? Function()? saveErrorMessage,
    ClientProfile? Function()? lastSavedClient,
  }) {
    return BusinessClientsState(
      status: status ?? this.status,
      query: query ?? this.query,
      result: result != null ? result() : this.result,
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
    errorMessage,
    saveStatus,
    saveErrorMessage,
    lastSavedClient,
  ];
}
