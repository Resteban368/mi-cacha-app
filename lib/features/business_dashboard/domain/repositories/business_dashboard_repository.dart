import '../entities/business_dashboard.dart';

/// Lanza `DashboardException` cuando la API rechaza la consulta.
abstract interface class BusinessDashboardRepository {
  Future<BusinessDashboard> getDashboard(DashboardFilter filter);
}
