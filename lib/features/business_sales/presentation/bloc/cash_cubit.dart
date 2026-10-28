import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/cash_session.dart';
import '../../domain/usecases/cash_usecases.dart';

enum CashLoad { loading, ready, failure }

final class CashState extends Equatable {
  const CashState({
    this.load = CashLoad.loading,
    this.status = const CashStatus(),
  });

  final CashLoad load;
  final CashStatus status;

  CashSession? get session => status.session;
  bool get isOpen => status.session != null;

  CashState copyWith({CashLoad? load, CashStatus? status}) =>
      CashState(load: load ?? this.load, status: status ?? this.status);

  @override
  List<Object?> get props => [load, status];
}

/// Caja del negocio: abrir con base, ver lo cobrado y cerrar con arqueo.
class CashCubit extends Cubit<CashState> {
  CashCubit({
    required GetCashStatus getStatus,
    required OpenCash openCash,
    required CloseCash closeCash,
    required GetCashHistory getHistory,
  }) : _getStatus = getStatus,
       _open = openCash,
       _close = closeCash,
       _history = getHistory,
       super(const CashState());

  final GetCashStatus _getStatus;
  final OpenCash _open;
  final CloseCash _close;
  final GetCashHistory _history;

  static const historyPageSize = 20;

  Future<void> load() async {
    try {
      final status = await _getStatus(const NoParams());
      if (isClosed) return;
      emit(state.copyWith(load: CashLoad.ready, status: status));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(load: CashLoad.failure));
    }
  }

  /// Devuelve el error para mostrar, o `null` si se abrió.
  Future<String?> openCash(int openingCash, {String? note}) async {
    final error = await _guard(() => _open((amount: openingCash, note: note)));
    if (error == null) await load();
    return error;
  }

  /// Cierra con el efectivo contado. Devuelve el cierre o el error.
  Future<({CashSession? closed, String? error})> closeCash(
    int countedCash, {
    String? note,
  }) async {
    CashSession? closed;
    final error = await _guard(() async {
      closed = await _close((amount: countedCash, note: note));
      return closed!;
    });
    if (error == null) await load();
    return (closed: closed, error: error);
  }

  Future<({List<CashSession> items, int total})> history(int page) =>
      _history((page: page, pageSize: historyPageSize));

  Future<String?> _guard(Future<CashSession> Function() request) async {
    try {
      await request();
      return null;
    } on ArgumentError catch (error) {
      return '${error.message}';
    } on ApiException catch (error) {
      return switch (error.kind) {
        ApiErrorKind.network =>
          'Sin conexión. Revisa tu internet e intenta de nuevo.',
        ApiErrorKind.forbidden ||
        ApiErrorKind.conflict ||
        ApiErrorKind.badRequest =>
          error.message ?? 'No se pudo completar. Intenta de nuevo.',
        _ => 'No se pudo completar. Intenta de nuevo.',
      };
    } catch (_) {
      return 'No se pudo completar. Intenta de nuevo.';
    }
  }
}
