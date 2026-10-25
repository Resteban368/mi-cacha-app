import 'package:shared_preferences/shared_preferences.dart';

import 'appearance_mode.dart';

/// Guarda el modo elegido en el dispositivo. Dato no sensible:
/// SharedPreferences (no secure storage).
class AppearanceStorage {
  const AppearanceStorage(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _key = 'appearance_mode';

  Future<AppearanceMode> read() async {
    try {
      return AppearanceMode.fromStorage(await _prefs.getString(_key));
    } catch (_) {
      // Sin almacenamiento disponible se sigue el sistema.
      return AppearanceMode.system;
    }
  }

  Future<void> write(AppearanceMode mode) =>
      _prefs.setString(_key, mode.storageCode);
}
