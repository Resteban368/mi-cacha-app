import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'notifications_bell_scope.dart';

/// Barra superior de las secciones internas: título, subtítulo y
/// notificaciones sobre un degradado teal con líneas de cancha sutiles.
///
/// Si el `Scaffold` contenedor tiene menú lateral (`drawer`), a la izquierda
/// se muestra el botón para abrirlo (también junto a "Volver"); si no, la
/// insignia con [icon].
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.hasUnread = false,
    this.onNotifications,
    this.onBack,
    this.showNotifications = true,
    this.titleBadge,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool hasUnread;
  final VoidCallback? onNotifications;

  /// Si se indica, se muestra el botón "Volver" (seguido del menú, si hay).
  final VoidCallback? onBack;
  final bool showNotifications;

  /// Etiqueta junto al título (p. ej. "Manual").
  final String? titleBadge;

  static const _radius = Radius.circular(24);

  /// El `Scaffold` más cercano que tenga menú lateral: las pantallas con
  /// su propio `Scaffold` (p. ej. "Crear Reserva") abren el del panel.
  static ScaffoldState? _drawerScaffold(BuildContext context) {
    ScaffoldState? found;
    context.visitAncestorElements((element) {
      if (element is StatefulElement &&
          element.state is ScaffoldState &&
          (element.state as ScaffoldState).hasDrawer) {
        found = element.state as ScaffoldState;
        return false;
      }
      return true;
    });
    return found;
  }

  @override
  Widget build(BuildContext context) {
    // La campana toma la insignia y la acción del panel, si no se le pasan.
    final bell = NotificationsBellScope.maybeOf(context);
    final hasUnread = this.hasUnread || (bell?.unread ?? 0) > 0;
    final onNotifications = this.onNotifications ?? bell?.onOpen;
    final scaffold = _drawerScaffold(context);
    final hasDrawer = scaffold != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(bottom: _radius),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: _radius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.isDark
                    ? [AppColors.surfaceContainerHigh, AppColors.brandTealLight]
                    : [AppColors.brandTeal, AppColors.primary],
              ),
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _CourtLinesPainter()),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
                    child: Row(
                      children: [
                        if (onBack != null) ...[
                          _GlassButton(
                            tooltip: 'Volver',
                            onPressed: onBack!,
                            shape: BoxShape.rectangle,
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 24,
                              color: AppColors.onPrimary,
                            ),
                          ),
                          if (hasDrawer) ...[
                            const SizedBox(width: 8),
                            _GlassButton(
                              tooltip: 'Abrir menú',
                              onPressed: scaffold.openDrawer,
                              shape: BoxShape.rectangle,
                              child: const Icon(
                                Icons.menu_rounded,
                                size: 24,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ],
                        ] else if (hasDrawer)
                          _GlassButton(
                            tooltip: 'Abrir menú',
                            onPressed: scaffold.openDrawer,
                            shape: BoxShape.rectangle,
                            child: const Icon(
                              Icons.menu_rounded,
                              size: 24,
                              color: AppColors.onPrimary,
                            ),
                          )
                        else
                          _Badge(icon: icon),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Semantics(
                                      header: true,
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.headlineLg
                                            .copyWith(
                                              color: AppColors.onPrimary,
                                              height: 1.1,
                                            ),
                                      ),
                                    ),
                                  ),
                                  // En pantallas angostas el título tiene
                                  // prioridad.
                                  if (titleBadge case final badge?
                                      when MediaQuery.sizeOf(context).width >=
                                          600) ...[
                                    const SizedBox(width: 8),
                                    _TitleBadge(badge),
                                  ],
                                ],
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.onPrimary.withValues(
                                      alpha: 0.78,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (showNotifications) ...[
                          const SizedBox(width: 8),
                          _GlassButton(
                            tooltip: 'Notificaciones',
                            semanticLabel: hasUnread
                                ? 'Notificaciones, tienes nuevas'
                                : 'Notificaciones',
                            onPressed: onNotifications ?? () {},
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 24,
                                  color: AppColors.onPrimary,
                                ),
                                if (hasUnread)
                                  Positioned(
                                    top: 10,
                                    right: 11,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: AppColors.accentLime,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.brandTeal,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Insignia con el ícono de la sección (cuando no hay menú desplegable).
class _Badge extends StatelessWidget {
  const _Badge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.onPrimary.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, size: 24, color: AppColors.accentLime),
    );
  }
}

/// Botón translúcido de 44px (menú y notificaciones).
class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.shape = BoxShape.circle,
  });

  final String tooltip;
  final String? semanticLabel;
  final VoidCallback onPressed;
  final Widget child;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final border = shape == BoxShape.circle
        ? const CircleBorder()
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: AppColors.onPrimary.withValues(alpha: 0.18),
            ),
          );
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: semanticLabel ?? tooltip,
        excludeSemantics: true,
        child: Material(
          color: AppColors.onPrimary.withValues(alpha: 0.12),
          shape: border,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(dimension: 44, child: child),
          ),
        ),
      ),
    );
  }
}

/// Media cancha a la derecha (círculo central + línea), muy tenue.
class _CourtLinesPainter extends CustomPainter {
  const _CourtLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = Offset(size.width - 40, size.height * 0.55);

    canvas
      ..drawCircle(center, 46, paint)
      ..drawCircle(center, 4, paint..style = PaintingStyle.fill)
      ..drawLine(
        Offset(center.dx, 0),
        Offset(center.dx, size.height),
        paint..style = PaintingStyle.stroke,
      )
      ..drawCircle(
        Offset(size.width * 0.45, -30),
        70,
        paint..color = Colors.white.withValues(alpha: 0.05),
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TitleBadge extends StatelessWidget {
  const _TitleBadge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentLime.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accentLime.withValues(alpha: 0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.labelSm.copyWith(
          color: AppColors.accentLime,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
