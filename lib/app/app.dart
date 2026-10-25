import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/appearance/appearance_cubit.dart';
import '../core/appearance/appearance_mode.dart';
import '../core/di/injection_container.dart';
import '../core/router/app_router.dart';
import '../core/session/session_manager.dart';
import '../core/session/write_access.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Activa la paleta del [mode]; `true` si cambió.
bool applyAppearance(AppearanceMode mode) => AppColors.use(switch (mode) {
  AppearanceMode.system =>
    WidgetsBinding.instance.platformDispatcher.platformBrightness,
  AppearanceMode.light => Brightness.light,
  AppearanceMode.dark => Brightness.dark,
});

class MiCanchaApp extends StatefulWidget {
  const MiCanchaApp({super.key});

  @override
  State<MiCanchaApp> createState() => _MiCanchaAppState();
}

class _MiCanchaAppState extends State<MiCanchaApp> with WidgetsBindingObserver {
  late final GoRouter _router = buildAppRouter(sl<SessionManager>());
  final _appearance = sl<AppearanceCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  /// "Sistema": el usuario cambió el modo del dispositivo.
  @override
  void didChangePlatformBrightness() => _apply(_appearance.state);

  /// Los colores son tokens globales ([AppColors]): al cambiar de modo se
  /// reconstruye todo el árbol (también los widgets `const`), sin perder
  /// la navegación ni el estado.
  void _apply(AppearanceMode mode) {
    if (!applyAppearance(mode)) return;
    setState(() {});
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _appearance,
      child: BlocListener<AppearanceCubit, AppearanceMode>(
        listener: (_, mode) => _apply(mode),
        child: WriteAccessScope(
          notifier: sl<WriteAccess>(),
          child: MaterialApp.router(
            title: 'Mi Cancha',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.current,
            routerConfig: _router,
            locale: const Locale('es', 'CO'),
            supportedLocales: const [Locale('es', 'CO'), Locale('es')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      ),
    );
  }
}
