import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/cash_session.dart';
import '../../domain/repositories/cash_repository.dart';

/// Turnos de caja en la API (`/business/cash`).
class CashApiDataSource implements CashRepository {
  const CashApiDataSource(this._dio);

  final Dio _dio;

  static const _path = '/business/cash';

  @override
  Future<CashStatus> current() async {
    final response = await apiCall(
      () => _dio.get<Map<String, dynamic>>('$_path/current'),
    );
    final json = response.data ?? const {};
    return CashStatus(
      session: switch (json['session']) {
        final Map<String, dynamic> s => sessionFromJson(s),
        _ => null,
      },
      lastClosed: switch (json['lastClosed']) {
        final Map<String, dynamic> s => sessionFromJson(s),
        _ => null,
      },
    );
  }

  @override
  Future<CashSession> open({required int openingCash, String? note}) async {
    final text = note?.trim();
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(
        '$_path/open',
        data: {
          'openingCash': openingCash,
          if (text != null && text.isNotEmpty) 'note': text,
        },
      ),
    );
    return sessionFromJson(response.data!);
  }

  @override
  Future<CashSession> close({required int countedCash, String? note}) async {
    final text = note?.trim();
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(
        '$_path/close',
        data: {
          'countedCash': countedCash,
          if (text != null && text.isNotEmpty) 'note': text,
        },
      ),
    );
    return sessionFromJson(response.data!);
  }

  @override
  Future<({List<CashSession> items, int total})> history({
    required int page,
    required int pageSize,
  }) async {
    final response = await apiCall(
      () => _dio.get<Map<String, dynamic>>(
        '$_path/sessions',
        queryParameters: {'page': page, 'pageSize': pageSize},
      ),
    );
    final json = response.data ?? const {};
    return (
      items: [
        for (final item in (json['items'] as List<dynamic>? ?? const []))
          sessionFromJson(item as Map<String, dynamic>),
      ],
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  static int _money(Object? value) => (value as num? ?? 0).round();

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value).toLocal() : null;

  static CashSession sessionFromJson(Map<String, dynamic> json) => CashSession(
    id: json['id'] as String,
    openingCash: _money(json['openingCash']),
    openingNote: json['openingNote'] as String?,
    openedAt: _date(json['openedAt'])!,
    openedByName: json['openedByName'] as String?,
    closedAt: _date(json['closedAt']),
    closedByName: json['closedByName'] as String?,
    closingNote: json['closingNote'] as String?,
    expectedCash: _money(json['expectedCash']),
    countedCash: json['countedCash'] == null
        ? null
        : _money(json['countedCash']),
    difference: json['difference'] == null ? null : _money(json['difference']),
    methods: [
      for (final m in (json['methods'] as List<dynamic>? ?? const []))
        if (m case final Map<String, dynamic> m)
          CashMethodTotal(
            code: m['code'] as String? ?? '',
            name: m['name'] as String? ?? '',
            count: (m['count'] as num?)?.toInt() ?? 0,
            amount: _money(m['amount']),
          ),
    ],
    collected: _money(json['collected']),
  );
}
