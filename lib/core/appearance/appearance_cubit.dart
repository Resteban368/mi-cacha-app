import 'package:flutter_bloc/flutter_bloc.dart';

import 'appearance_mode.dart';
import 'appearance_storage.dart';

/// Modo de apariencia de la app (claro, oscuro o el del sistema).
class AppearanceCubit extends Cubit<AppearanceMode> {
  AppearanceCubit(this._storage) : super(AppearanceMode.system);

  final AppearanceStorage _storage;

  /// Lee el modo guardado (antes del primer cuadro, para no parpadear).
  Future<void> load() async => emit(await _storage.read());

  Future<void> select(AppearanceMode mode) async {
    if (mode == state) return;
    emit(mode);
    try {
      await _storage.write(mode);
    } catch (_) {
      // Si no se pudo guardar, el cambio vale para esta sesión.
    }
  }
}
