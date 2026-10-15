import '../../../../core/usecase/usecase.dart';
import '../entities/court.dart';
import '../entities/court_failure.dart';
import '../repositories/courts_repository.dart';

class CreateCourt implements UseCase<Court, CourtDraft> {
  const CreateCourt(this._repository);

  final CourtsRepository _repository;

  /// Valida lo que la API rechazaría (nombre, tarifas que se cruzan) antes
  /// de enviarlo, con un mensaje claro para el administrador.
  @override
  Future<Court> call(CourtDraft draft) async {
    final error = validate(draft);
    if (error != null) {
      throw CourtException(CourtFailure.invalid, message: error);
    }
    return _repository.create(draft);
  }

  /// `null` si el borrador es válido (la misma regla vale al editar).
  static String? validate(CourtDraft draft) {
    final name = draft.name.trim();
    if (name.isEmpty) return 'Ingresa el nombre de la cancha.';
    if (name.length > CourtDraft.maxNameLength) {
      return 'El nombre admite hasta ${CourtDraft.maxNameLength} caracteres.';
    }
    if (draft.basePricePerHour <= 0) {
      return 'Ingresa el precio base por hora.';
    }
    if (!draft.schedules.any((s) => s.isOpen)) {
      return 'Abre la cancha al menos un día de la semana.';
    }
    final rates = draft.rates;
    for (var i = 0; i < rates.length; i++) {
      for (var j = i + 1; j < rates.length; j++) {
        if (rates[i].overlaps(rates[j])) {
          return 'Las tarifas "${rates[i].name}" y "${rates[j].name}" '
              'se cruzan.';
        }
      }
    }
    return null;
  }
}
