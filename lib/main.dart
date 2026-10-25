import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/appearance/appearance_cubit.dart';
import 'core/di/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  // El modo guardado se aplica antes del primer cuadro (sin parpadeo).
  final appearance = sl<AppearanceCubit>();
  await appearance.load();
  applyAppearance(appearance.state);
  runApp(const MiCanchaApp());
}
