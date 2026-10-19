import '../../../../core/usecase/usecase.dart';
import '../entities/business_dashboard.dart';
import '../entities/dashboard_failure.dart';
import '../repositories/business_dashboard_repository.dart';

/// Métricas del negocio en el período y con los filtros indicados.
class GetBusinessDashboard
    implements UseCase<BusinessDashboard, DashboardFilter> {
  const GetBusinessDashboard(this._repository);

  final BusinessDashboardRepository _repository;

  /// Lo que la API rechazaría con un rango personalizado.
  static String? validate(DashboardFilter filter) {
    if (filter.period != DashboardPeriod.custom) return null;
    final from = filter.from;
    final to = filter.to;
    if (from == null || to == null) return 'Elige las fechas del período.';
    if (to.isBefore(from)) {
      return 'La fecha final no puede ser anterior a la inicial.';
    }
    final days =
        DateTime.utc(
          to.year,
          to.month,
          to.day,
        ).difference(DateTime.utc(from.year, from.month, from.day)).inDays +
        1;
    if (days > DashboardFilter.maxCustomDays) {
      return 'El período puede tener como máximo '
          '${DashboardFilter.maxCustomDays} días.';
    }
    return null;
  }

  @override
  Future<BusinessDashboard> call(DashboardFilter filter) async {
    if (validate(filter) case final error?) {
      throw DashboardException(DashboardFailure.invalid, message: error);
    }
    return _repository.getDashboard(filter);
  }
}
