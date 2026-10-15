import '../../domain/entities/business.dart';
import '../../../../core/media/image_upload.dart';
import '../../domain/repositories/business_repository.dart';
import '../datasources/business_data_source.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  const BusinessRepositoryImpl(this._dataSource);

  final BusinessDataSource _dataSource;

  @override
  Future<Business?> getMyBusiness() => _dataSource.getMyBusiness();

  @override
  Future<Business> save(BusinessDraft draft) => _dataSource.save(draft);

  @override
  Future<Business> uploadCover(ImageUpload image) =>
      _dataSource.uploadCover(image);

  @override
  Future<Business> removeCover() => _dataSource.removeCover();
}
