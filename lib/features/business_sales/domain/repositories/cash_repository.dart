import '../entities/cash_session.dart';

abstract interface class CashRepository {
  Future<CashStatus> current();

  Future<CashSession> open({required int openingCash, String? note});

  Future<CashSession> close({required int countedCash, String? note});

  /// Cierres anteriores, más recientes primero.
  Future<({List<CashSession> items, int total})> history({
    required int page,
    required int pageSize,
  });
}
