import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/write_access.dart';
import '../../../../core/theme/app_colors.dart';
import '../navigation/business_section.dart';
import '../widgets/business_logout.dart';
import '../widgets/business_side_menu.dart';
import '../widgets/read_only_banner.dart';

/// Contenedor del home de negocio: la sección actual + menú lateral.
///
/// - Pantallas angostas (móvil/tablet): menú en `Drawer`, se abre con el
///   botón ☰ de la barra superior (`AppTopBar`) o deslizando desde el borde.
/// - Pantallas anchas (≥ [wideBreakpoint]): menú fijo a la izquierda.
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
  });

  static const maxContentWidth = 480.0;
  static const wideBreakpoint = 1024.0;
  static const _sidebarWidth = 280.0;

  /// URL actual; determina la sección activa.
  final String location;

  /// Cierra la sesión (borra el token) al confirmar "Cerrar sesión".
  final Future<void> Function() onSignOut;
  final Widget child;

  void _select(BuildContext context, BusinessSection section) =>
      context.go(section.path);

  @override
  Widget build(BuildContext context) {
    final current = BusinessSection.fromLocation(location);
    final isWide = MediaQuery.sizeOf(context).width >= wideBreakpoint;

    final menu = BusinessSideMenu(
      current: current,
      onSelected: (section) => _select(context, section),
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
    // Sin plan activo: franja de solo lectura debajo de la sección.
    final content = WriteAccessScope.canWrite(context)
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
              const ReadOnlyBanner(),
            ],
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.surface,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        drawer: isWide
            ? null
            : Drawer(
                width: 304,
                backgroundColor: AppColors.surfaceContainerLowest,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(24),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: menu,
              ),
        body: isWide
            ? Row(
                children: [
                  SizedBox(
                    width: _sidebarWidth,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 16,
                            offset: Offset(4, 0),
                          ),
                        ],
                      ),
                      child: menu,
                    ),
                  ),
                  Expanded(child: content),
                ],
              )
            : content,
      ),
    );
  }
}
