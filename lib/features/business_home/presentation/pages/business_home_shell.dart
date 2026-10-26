import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../business_setup/domain/entities/setup_progress.dart';
import '../../../business_setup/presentation/business_setup_gate.dart';
import '../../../business_setup/presentation/widgets/setup_banner.dart';
import '../navigation/business_section.dart';
import '../widgets/business_logout.dart';
import '../widgets/business_side_menu.dart';
import '../widgets/read_only_banner.dart';

/// Contenedor del home de negocio: la sección actual + menú lateral.
///
/// El menú está escondido en todos los tamaños (deja todo el ancho a la
/// sección): es un `Drawer` que se abre con el botón ☰ de la barra superior
/// (`AppTopBar`) o deslizando desde el borde.
///
/// Las secciones se centran en [maxContentWidth] salvo las marcadas con
/// [BusinessSection.fullWidth], que ocupan todo el ancho (web/escritorio).
///
/// Se usa en un ShellRoute, por lo que solo la sección visible está montada.
class BusinessHomeShell extends StatelessWidget {
  const BusinessHomeShell({
    super.key,
    required this.location,
    required this.onSignOut,
    required this.child,
    this.setup,
  });

  static const maxContentWidth = 480.0;

  /// Desde este ancho las secciones usan su diseño de escritorio.
  static const wideBreakpoint = 1024.0;

  /// URL actual; determina la sección activa.
  final String location;

  /// Cierra la sesión (borra el token) al confirmar "Cerrar sesión".
  final Future<void> Function() onSignOut;
  final Widget child;

  /// Configuración inicial pendiente: bloquea secciones y muestra el paso.
  final BusinessSetupGate? setup;

  void _select(BuildContext context, BusinessSection section, SetupStep step) {
    if (step.allows(section.path)) {
      context.go(section.path);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(SetupBanner.lockedMessage(step))));
  }

  @override
  Widget build(BuildContext context) {
    final setup = this.setup;
    if (setup == null) return _build(context, null);
    return BusinessSetupScope(
      gate: setup,
      child: ListenableBuilder(
        listenable: setup,
        builder: (context, _) => _build(context, setup.progress),
      ),
    );
  }

  Widget _build(BuildContext context, SetupProgress? progress) {
    final current = BusinessSection.fromLocation(location);
    // Sin dato (cargando o sin conexión) no se bloquea nada.
    final step = progress?.step ?? SetupStep.done;

    final menu = BusinessSideMenu(
      current: current,
      locked: {
        for (final section in BusinessSection.values)
          if (!step.allows(section.path)) section,
      },
      onSelected: (section) => _select(context, section, step),
      onLogout: () => confirmBusinessLogout(context, signOut: onSignOut),
    );

    final section = current.fullWidth
        ? child
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: child,
            ),
          );
    // Franjas debajo de la sección: configuración pendiente y, sin plan
    // activo, solo lectura.
    final banners = [
      if (progress != null && progress.step != SetupStep.done)
        SetupBanner(progress: progress),
      if (!WriteAccessScope.canWrite(context)) const ReadOnlyBanner(),
    ];
    final content = banners.isEmpty
        ? section
        : Column(
            children: [
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: section,
                ),
              ),
              for (final (i, banner) in banners.indexed)
                // Solo la última franja necesita el margen inferior seguro.
                i == banners.length - 1
                    ? banner
                    : MediaQuery.removePadding(
                        context: context,
                        removeBottom: true,
                        child: banner,
                      ),
            ],
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.surface,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        drawer: Drawer(
          width: 304,
          backgroundColor: AppColors.surfaceContainerLowest,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
          child: menu,
        ),
        body: content,
      ),
    );
  }
}
