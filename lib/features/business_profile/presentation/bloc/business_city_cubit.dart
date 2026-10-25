import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/catalogs/domain/entities/catalog_geography.dart';
import '../../../../core/catalogs/domain/usecases/geography_usecases.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/business.dart';

enum GeographyLoad { idle, loading, ready, failure }

final class BusinessCityState extends Equatable {
  const BusinessCityState({
    this.departmentsStatus = GeographyLoad.idle,
    this.departments = const [],
    this.department,
    this.citiesStatus = GeographyLoad.idle,
    this.cities = const [],
    this.city,
    this.showErrors = false,
  });

  final GeographyLoad departmentsStatus;
  final List<CatalogDepartment> departments;
  final CatalogDepartment? department;

  /// Municipios del [department] elegido.
  final GeographyLoad citiesStatus;
  final List<CatalogCity> cities;
  final CatalogCity? city;

  /// Se marcan los obligatorios tras intentar guardar.
  final bool showErrors;

  String? get departmentError =>
      showErrors && department == null ? 'Elige el departamento' : null;

  String? get cityError =>
      showErrors && city == null ? 'Elige la ciudad' : null;

  BusinessCityState copyWith({
    GeographyLoad? departmentsStatus,
    List<CatalogDepartment>? departments,
    CatalogDepartment? Function()? department,
    GeographyLoad? citiesStatus,
    List<CatalogCity>? cities,
    CatalogCity? Function()? city,
    bool? showErrors,
  }) => BusinessCityState(
    departmentsStatus: departmentsStatus ?? this.departmentsStatus,
    departments: departments ?? this.departments,
    department: department != null ? department() : this.department,
    citiesStatus: citiesStatus ?? this.citiesStatus,
    cities: cities ?? this.cities,
    city: city != null ? city() : this.city,
    showErrors: showErrors ?? this.showErrors,
  );

  @override
  List<Object?> get props => [
    departmentsStatus,
    departments,
    department,
    citiesStatus,
    cities,
    city,
    showErrors,
  ];
}

/// Departamento y ciudad del negocio: dos selectores dependientes. La
/// ciudad se habilita al elegir el departamento y se limpia si este cambia.
class BusinessCityCubit extends Cubit<BusinessCityState> {
  BusinessCityCubit({
    required GetDepartments getDepartments,
    required GetCities getCities,
  }) : _getDepartments = getDepartments,
       _getCities = getCities,
       super(const BusinessCityState());

  final GetDepartments _getDepartments;
  final GetCities _getCities;

  /// Sube con cada departamento elegido: los municipios que llegan tarde
  /// de uno anterior se descartan.
  int _citiesGeneration = 0;

  /// Carga los departamentos y, al editar, deja elegidos el departamento y
  /// la ciudad actuales ([initial]).
  Future<void> load({City? initial}) async {
    if (initial != null) {
      emit(
        state.copyWith(
          department: () => CatalogDepartment(
            id: initial.departmentId,
            code: '',
            name: initial.departmentName,
          ),
          city: () => CatalogCity(id: initial.id, code: '', name: initial.name),
        ),
      );
    }
    await Future.wait([
      _loadDepartments(),
      if (initial != null) _loadCities(initial.departmentId),
    ]);
    // Con la lista cargada se usan sus datos completos (código DANE).
    final department = state.departments
        .where((d) => d.id == state.department?.id)
        .firstOrNull;
    final city = state.cities.where((c) => c.id == state.city?.id).firstOrNull;
    if (isClosed) return;
    emit(
      state.copyWith(
        department: department == null ? null : () => department,
        city: city == null ? null : () => city,
      ),
    );
  }

  Future<void> retryDepartments() => _loadDepartments();

  Future<void> retryCities() async {
    final department = state.department;
    if (department != null) await _loadCities(department.id);
  }

  /// Elegir otro departamento limpia la ciudad y carga sus municipios.
  Future<void> selectDepartment(CatalogDepartment department) async {
    if (department.id == state.department?.id) return;
    emit(
      state.copyWith(
        department: () => department,
        city: () => null,
        cities: const [],
      ),
    );
    await _loadCities(department.id);
  }

  void selectCity(CatalogCity city) => emit(state.copyWith(city: () => city));

  /// Marca los obligatorios; `true` si están el departamento y la ciudad.
  bool validate() {
    emit(state.copyWith(showErrors: true));
    return state.department != null && state.city != null;
  }

  Future<void> _loadDepartments() async {
    emit(state.copyWith(departmentsStatus: GeographyLoad.loading));
    try {
      final departments = await _getDepartments(const NoParams());
      if (isClosed) return;
      emit(
        state.copyWith(
          departments: departments,
          departmentsStatus: GeographyLoad.ready,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(departmentsStatus: GeographyLoad.failure));
    }
  }

  Future<void> _loadCities(String departmentId) async {
    final generation = ++_citiesGeneration;
    emit(state.copyWith(citiesStatus: GeographyLoad.loading));
    try {
      final cities = await _getCities(departmentId);
      if (isClosed || generation != _citiesGeneration) return;
      emit(state.copyWith(cities: cities, citiesStatus: GeographyLoad.ready));
    } catch (_) {
      if (isClosed || generation != _citiesGeneration) return;
      emit(state.copyWith(citiesStatus: GeographyLoad.failure));
    }
  }
}
