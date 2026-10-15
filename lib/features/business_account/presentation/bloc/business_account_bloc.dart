import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../business_profile/domain/entities/business.dart';
import '../../../business_profile/domain/usecases/get_my_business.dart';
import '../../../splash/domain/usecases/get_app_version.dart';
import '../../domain/entities/business_account.dart';
import '../../domain/usecases/get_business_account.dart';

part 'business_account_event.dart';
part 'business_account_state.dart';

class BusinessAccountBloc
    extends Bloc<BusinessAccountEvent, BusinessAccountState> {
  BusinessAccountBloc({
    required GetBusinessAccount getAccount,
    required GetMyBusiness getMyBusiness,
    required GetAppVersion getAppVersion,
  }) : _getAccount = getAccount,
       _getMyBusiness = getMyBusiness,
       _getAppVersion = getAppVersion,
       super(const BusinessAccountState()) {
    on<BusinessAccountRequested>(_onRequested, transformer: restartable());
  }

  final GetBusinessAccount _getAccount;
  final GetMyBusiness _getMyBusiness;
  final GetAppVersion _getAppVersion;

  Future<void> _onRequested(
    BusinessAccountRequested event,
    Emitter<BusinessAccountState> emit,
  ) async {
    emit(state.copyWith(status: BusinessAccountStatus.loading));
    try {
      final (account, venue, version) = await (
        _getAccount(const NoParams()),
        _getMyBusiness(const NoParams()),
        _versionOrNull(),
      ).wait;
      emit(
        BusinessAccountState(
          status: BusinessAccountStatus.ready,
          account: account,
          venue: venue,
          version: version,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: BusinessAccountStatus.failure));
    }
  }

  /// La versión es informativa: si falla, la pantalla se muestra igual.
  Future<String?> _versionOrNull() async {
    try {
      return await _getAppVersion(const NoParams());
    } catch (_) {
      return null;
    }
  }
}
