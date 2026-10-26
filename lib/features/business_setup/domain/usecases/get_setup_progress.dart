import '../../../../core/usecase/usecase.dart';
import '../../../business_courts/domain/repositories/courts_repository.dart';
import '../../../business_profile/domain/entities/business.dart';
import '../../../business_profile/domain/repositories/business_repository.dart';
import '../entities/setup_progress.dart';

/// Primero el negocio completo; después, al menos una cancha lista para
/// recibir reservas (activa y con la foto principal, según la API).
class GetSetupProgress implements UseCase<SetupProgress, NoParams> {
  const GetSetupProgress(this._businessRepository, this._courtsRepository);

  final BusinessRepository _businessRepository;
  final CourtsRepository _courtsRepository;

  @override
  Future<SetupProgress> call(NoParams params) async {
    final business = await _businessRepository.getMyBusiness();
    final missing = business?.missingRequirements ?? BusinessRequirement.values;
    if (missing.isNotEmpty) {
      return SetupProgress(SetupStep.business, missing: missing);
    }
    final courts = await _courtsRepository.getCourts();
    if (!courts.any((court) => court.isBookable)) {
      return const SetupProgress(SetupStep.court);
    }
    return SetupProgress.done;
  }
}
