import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/di/injection_container.dart';
import '../core/router/app_router.dart';
import '../core/session/session_manager.dart';
import '../core/session/write_access.dart';
import '../core/theme/app_theme.dart';

class MiCanchaApp extends StatefulWidget {
  const MiCanchaApp({super.key});

  @override
  State<MiCanchaApp> createState() => _MiCanchaAppState();
}

class _MiCanchaAppState extends State<MiCanchaApp> {
  late final GoRouter _router = buildAppRouter(sl<SessionManager>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WriteAccessScope(
      notifier: sl<WriteAccess>(),
      child: MaterialApp.router(
        title: 'Mi Cancha',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        locale: const Locale('es', 'CO'),
        supportedLocales: const [
          Locale('es', 'CO'),
          Locale('es'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
