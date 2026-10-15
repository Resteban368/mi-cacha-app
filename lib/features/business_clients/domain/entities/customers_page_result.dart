import 'package:equatable/equatable.dart';

import 'client_profile.dart';
import 'customer_overview.dart';

/// Resultado paginado de clientes devuelto por la API.
class CustomersPageResult extends Equatable {
  const CustomersPageResult({
    required this.overview,
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory CustomersPageResult.fromJson(Map<String, dynamic> json) {
    final overviewJson = json['overview'];
    final overview = overviewJson is Map<String, dynamic>
        ? CustomerOverview.fromJson(overviewJson)
        : const CustomerOverview();

    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(ClientProfile.fromJson)
              .toList()
        : <ClientProfile>[];

    return CustomersPageResult(
      overview: overview,
      items: items,
      total: (json['total'] as num?)?.toInt() ?? items.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
    );
  }

  final CustomerOverview overview;
  final List<ClientProfile> items;
  final int total;
  final int page;
  final int pageSize;

  int get totalPages => pageSize > 0 ? (total / pageSize).ceil() : 1;
  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  @override
  List<Object?> get props => [overview, items, total, page, pageSize];
}
