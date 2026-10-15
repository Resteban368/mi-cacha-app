import 'package:package_info_plus/package_info_plus.dart';

abstract interface class AppInfoDataSource {
  Future<String> getVersion();
}

class AppInfoDataSourceImpl implements AppInfoDataSource {
  @override
  Future<String> getVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }
}
