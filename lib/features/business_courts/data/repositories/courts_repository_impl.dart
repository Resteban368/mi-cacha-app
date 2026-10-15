import '../../../../core/media/image_upload.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/court.dart';
import '../../domain/entities/court_failure.dart';
import '../../domain/repositories/courts_repository.dart';
import '../datasources/courts_data_source.dart';

class CourtsRepositoryImpl implements CourtsRepository {
  const CourtsRepositoryImpl(this._dataSource);

  final CourtsDataSource _dataSource;

  @override
  Future<List<Court>> getCourts() => _guard(_dataSource.getCourts);

  @override
  Future<Court> create(CourtDraft draft) =>
      _guard(() => _dataSource.create(draft));

  @override
  Future<Court> update(String courtId, CourtDraft draft) =>
      _guard(() => _dataSource.update(courtId, draft));

  @override
  Future<Court> removePhoto(String courtId, CourtPhotoSlot slot) =>
      _guard(() => _dataSource.removePhoto(courtId, slot));

  @override
  Future<Court> uploadPhoto(
    String courtId,
    CourtPhotoSlot slot,
    ImageUpload image,
  ) => _guard(() => _dataSource.uploadPhoto(courtId, slot, image));

  /// Traduce los errores de la API a [CourtException].
  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiException catch (error) {
      throw CourtException(switch (error) {
        // 403 PLAN_LIMIT_REACHED / PLAN_INACTIVE: el mensaje del backend
        // ya explica el límite ("Tu plan Básico permite 3 canchas…").
        ApiException(kind: ApiErrorKind.forbidden) => CourtFailure.planLimit,
        ApiException(kind: ApiErrorKind.conflict) => CourtFailure.duplicateName,
        ApiException(kind: ApiErrorKind.badRequest) => CourtFailure.invalid,
        // 404 al crear: el administrador aún no registró su negocio.
        ApiException(kind: ApiErrorKind.notFound) => CourtFailure.noBusiness,
        ApiException(kind: ApiErrorKind.network) => CourtFailure.network,
        _ => CourtFailure.server,
      }, message: error.message);
    }
  }
}
