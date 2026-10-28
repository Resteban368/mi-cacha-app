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
  Future<CashExpense> addExpense({
    required String supplierId,
    required int amount,
    required String method,
    required String concept,
  }) async {
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(
        '$_path/expenses',
        data: {
          'supplierId': supplierId,
          'amount': amount,
          'method': method,
          'concept': concept.trim(),
        },
      ),
    );
    return expenseFromJson(response.data!);
  }

  @override
  Future<CashExpense> voidExpense(String id, String reason) async {
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(
        '$_path/expenses/$id/void',
        data: {'reason': reason.trim()},
      ),
    );
    return expenseFromJson(response.data!);
  }

  @override
  Future<CashMovement> addMovement({
    required CashMovementType type,
    required int amount,
    required String reason,
  }) async {
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(
        '$_path/movements',
        data: {'type': type.apiCode, 'amount': amount, 'reason': reason.trim()},
      ),
    );
    return movementFromJson(response.data!);
  }

  @override
  Future<CashMovement> voidMovement(String id, String reason) async {
    final response = await apiCall(
      () => _dio.post<Map<String, dynamic>>(
        '$_path/movements/$id/void',
        data: {'reason': reason.trim()},
      ),
    );
    return movementFromJson(response.data!);
  }

  static const _suppliers = '/business/suppliers';

  @override
  Future<List<Supplier>> suppliers({bool includeInactive = false}) async {
    final response = await apiCall(
      () => _dio.get<List<dynamic>>(
        _suppliers,
        queryParameters: {if (includeInactive) 'includeInactive': true},
      ),
    );
    return [
      for (final item in response.data ?? const [])
        supplierFromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<Supplier> saveSupplier(SupplierDraft draft) async {
    String? text(String? value) {
      final t = value?.trim();
      return t == null || t.isEmpty ? null : t;
    }

    final data = {
      'name': draft.name.trim(),
      // Al editar, vacío borra el dato; al crear se omite.
      if (draft.id != null || text(draft.documentId) != null)
        'documentId': text(draft.documentId) ?? '',
      if (draft.id != null || text(draft.phone) != null)
        'phone': text(draft.phone) ?? '',
      if (draft.id != null || text(draft.notes) != null)
        'notes': text(draft.notes) ?? '',
    };
    final response = await apiCall(
      () => switch (draft.id) {
        final id? => _dio.patch<Map<String, dynamic>>(
          '$_suppliers/$id',
          data: data,
        ),
        null => _dio.post<Map<String, dynamic>>(_suppliers, data: data),
      },
    );
    return supplierFromJson(response.data!);
  }

  @override
  Future<Supplier> setSupplierActive(String id, bool isActive) async {
    final response = await apiCall(
      () => _dio.patch<Map<String, dynamic>>(
        '$_suppliers/$id',
        data: {'isActive': isActive},
      ),
    );
    return supplierFromJson(response.data!);
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

  static Supplier supplierFromJson(Map<String, dynamic> json) => Supplier(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    documentId: json['documentId'] as String?,
    phone: json['phone'] as String?,
    notes: json['notes'] as String?,
    isActive: json['isActive'] as bool? ?? true,
  );

  static CashExpense expenseFromJson(Map<String, dynamic> json) => CashExpense(
    id: json['id'] as String,
    supplierId: json['supplierId'] as String?,
    supplierName: json['supplierName'] as String? ?? '',
    amount: _money(json['amount']),
    method: json['method'] as String? ?? 'EFECTIVO',
    methodName: json['methodName'] as String?,
    concept: json['concept'] as String? ?? '',
    createdAt: _date(json['createdAt'])!,
    createdByName: json['createdByName'] as String?,
    voidedAt: _date(json['voidedAt']),
    voidReason: json['voidReason'] as String?,
  );

  static CashMovement movementFromJson(Map<String, dynamic> json) =>
      CashMovement(
        id: json['id'] as String,
        type: CashMovementType.fromApi(json['type'] as String?),
        amount: _money(json['amount']),
        reason: json['reason'] as String? ?? '',
        createdAt: _date(json['createdAt'])!,
        createdByName: json['createdByName'] as String?,
        voidedAt: _date(json['voidedAt']),
        voidReason: json['voidReason'] as String?,
      );

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
    expenses: [
      for (final e in (json['expenses'] as List<dynamic>? ?? const []))
        if (e case final Map<String, dynamic> e) expenseFromJson(e),
    ],
    expensesTotal: _money(json['expensesTotal']),
    cashExpensesTotal: _money(json['cashExpensesTotal']),
    movements: [
      for (final m in (json['movements'] as List<dynamic>? ?? const []))
        if (m case final Map<String, dynamic> m) movementFromJson(m),
    ],
    cashInTotal: _money(json['cashInTotal']),
    cashOutTotal: _money(json['cashOutTotal']),
    businessName: json['businessName'] as String? ?? '',
  );
}
