import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OnboardingLocalDataSource {
  Future<bool> readCompleted();

  Future<void> writeCompleted();
}

/// Bandera no sensible: se guarda en SharedPreferences (no en secure storage).
class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  const OnboardingLocalDataSourceImpl(this._prefs);

  static const _key = 'onboarding_completed';

  final SharedPreferencesAsync _prefs;

  @override
  Future<bool> readCompleted() async => await _prefs.getBool(_key) ?? false;

  @override
  Future<void> writeCompleted() => _prefs.setBool(_key, true);
}
