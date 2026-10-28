import '../../../../core/usecase/usecase.dart';
import '../entities/cash_session.dart';
import '../repositories/cash_repository.dart';

class GetCashStatus implements UseCase<CashStatus, NoParams> {
  const GetCashStatus(this._repository);

  final CashRepository _repository;

  @override
  Future<CashStatus> call(NoParams _) => _repository.current();
}

typedef CashAmountParams = ({int amount, String? note});

class OpenCash implements UseCase<CashSession, CashAmountParams> {
  const OpenCash(this._repository);

  final CashRepository _repository;

  @override
  Future<CashSession> call(CashAmountParams params) {
    if (params.amount < 0) {
      throw ArgumentError('La base no puede ser negativa.');
    }
    return _repository.open(openingCash: params.amount, note: params.note);
  }
}

class CloseCash implements UseCase<CashSession, CashAmountParams> {
  const CloseCash(this._repository);

  final CashRepository _repository;

  @override
  Future<CashSession> call(CashAmountParams params) {
    if (params.amount < 0) {
      throw ArgumentError('El efectivo contado no puede ser negativo.');
    }
    return _repository.close(countedCash: params.amount, note: params.note);
  }
}

typedef CashHistoryParams = ({int page, int pageSize});

class GetCashHistory
    implements
        UseCase<({List<CashSession> items, int total}), CashHistoryParams> {
  const GetCashHistory(this._repository);

  final CashRepository _repository;

  @override
  Future<({List<CashSession> items, int total})> call(
    CashHistoryParams params,
  ) => _repository.history(page: params.page, pageSize: params.pageSize);
}
