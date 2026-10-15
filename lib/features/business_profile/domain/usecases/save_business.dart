import '../../../../core/usecase/usecase.dart';
import '../entities/business.dart';
import '../repositories/business_repository.dart';

class SaveBusiness implements UseCase<Business, BusinessDraft> {
  const SaveBusiness(this._repository);

  final BusinessRepository _repository;

  @override
  Future<Business> call(BusinessDraft draft) {
    if (!draft.isComplete) {
      throw ArgumentError('Nombre, dirección y barrio son obligatorios');
    }
    return _repository.save(draft);
  }
}
