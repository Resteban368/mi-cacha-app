import '../../domain/repositories/app_info_repository.dart';
import '../datasources/app_info_data_source.dart';

class AppInfoRepositoryImpl implements AppInfoRepository {
  const AppInfoRepositoryImpl(this._dataSource);

  final AppInfoDataSource _dataSource;

  @override
  Future<String> getVersion() async {
    try {
      return await _dataSource.getVersion();
    } catch (_) {
      return '';
    }
  }
}
