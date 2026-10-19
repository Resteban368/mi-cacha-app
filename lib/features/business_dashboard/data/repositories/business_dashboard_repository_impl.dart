import '../../../../core/network/api_exception.dart';
import '../../domain/entities/business_dashboard.dart';
import '../../domain/entities/dashboard_failure.dart';
import '../../domain/repositories/business_dashboard_repository.dart';
import '../datasources/business_dashboard_api_data_source.dart';

class BusinessDashboardRepositoryImpl implements BusinessDashboardRepository {
  const BusinessDashboardRepositoryImpl(this._dataSource);

  final BusinessDashboardDataSource _dataSource;

  @override
  Future<BusinessDashboard> getDashboard(DashboardFilter filter) async {
    try {
      return await _dataSource.getDashboard(filter);
    } on ApiException catch (error) {
      throw DashboardException(switch (error.kind) {
        ApiErrorKind.badRequest => DashboardFailure.invalid,
        ApiErrorKind.notFound => DashboardFailure.notAvailable,
        ApiErrorKind.network => DashboardFailure.network,
        _ => DashboardFailure.server,
      }, message: error.message);
    }
  }
}
