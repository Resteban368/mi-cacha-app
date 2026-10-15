import 'package:equatable/equatable.dart';

import 'client_filter.dart';

/// Parámetros de consulta y paginación para el directorio de clientes en el backend.
class CustomerQuery extends Equatable {
  const CustomerQuery({
    this.page = 1,
    this.pageSize = 20,
    this.search = '',
    this.segment = ClientFilterType.all,
    this.sort = ClientSortBy.mostActive,
  });

  final int page;
  final int pageSize;
  final String search;
  final ClientFilterType segment;
  final ClientSortBy sort;

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'segment': segment.apiCode,
      'sort': sort.apiCode,
    };
    if (search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    return params;
  }

  CustomerQuery copyWith({
    int? page,
    int? pageSize,
    String? search,
    ClientFilterType? segment,
    ClientSortBy? sort,
  }) {
    return CustomerQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      segment: segment ?? this.segment,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [page, pageSize, search, segment, sort];
}
