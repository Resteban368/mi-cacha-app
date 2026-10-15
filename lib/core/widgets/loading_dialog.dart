import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Diálogo de carga de pantalla: ícono de la app, "Cargando información" y
/// el fondo difuminado. No se cierra con atrás ni tocando afuera.
class AppLoadingDialog extends StatelessWidget {
  const AppLoadingDialog({
    super.key,
    this.title = 'Cargando información',
    this.message = 'Espere un momento…',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Semantics(
                liveRegion: true,
                label: '$title. $message',
                excludeSemantics: true,
                child: Material(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  elevation: 12,
                  shadowColor: const Color(0x33000000),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SvgPicture.asset(
                            AppAssets.logo,
                            width: 64,
                            height: 64,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineSm.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: const LinearProgressIndicator(
                            minHeight: 4,
                            color: AppColors.brandTeal,
                            backgroundColor: AppColors.brandTealLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un único diálogo de carga por pantalla. Idempotente: mostrarlo dos veces
/// no apila diálogos, y se cierra con `removeRoute` (cierra ESA ruta, nunca
/// un `pop` a ciegas que podría cerrar otra cosa).
mixin LoadingDialogMixin<T extends StatefulWidget> on State<T> {
  /// Solo se muestra si la carga tarda más que esto (evita parpadeos).
  static const showDelay = Duration(milliseconds: 150);

  DialogRoute<void>? _route;
  NavigatorState? _navigator;
  Timer? _pending;

  bool get isLoadingDialogVisible => _route != null;

  void showLoadingDialog() {
    if (!mounted || _route != null || _pending != null) return;
    _pending = Timer(showDelay, () {
      _pending = null;
      if (!mounted || _route != null) return;
      final navigator = Navigator.of(context, rootNavigator: true);
      final route = DialogRoute<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0x4D0B1F1A),
        themes: InheritedTheme.capture(from: context, to: navigator.context),
        builder: (_) => const AppLoadingDialog(),
      );
      _route = route;
      _navigator = navigator;
      navigator.push(route).whenComplete(() {
        if (identical(_route, route)) {
          _route = null;
          _navigator = null;
        }
      });
    });
  }

  void hideLoadingDialog() {
    _pending?.cancel();
    _pending = null;
    final route = _route;
    final navigator = _navigator;
    if (route == null) return;
    _route = null;
    _navigator = null;
    if (route.isActive && navigator != null && navigator.mounted) {
      navigator.removeRoute(route);
    }
  }

  @override
  void dispose() {
    hideLoadingDialog();
    super.dispose();
  }
}

/// Muestra [AppLoadingDialog] mientras el estado del bloc [B] cumpla
/// [isLoading] (incluido el estado inicial) y lo cierra al terminar.
class BlocLoadingDialog<B extends StateStreamable<S>, S>
    extends StatefulWidget {
  const BlocLoadingDialog({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool Function(S state) isLoading;
  final Widget child;

  @override
  State<BlocLoadingDialog<B, S>> createState() => _BlocLoadingDialogState();
}

class _BlocLoadingDialogState<B extends StateStreamable<S>, S>
    extends State<BlocLoadingDialog<B, S>>
    with LoadingDialogMixin {
  @override
  void initState() {
    super.initState();
    // BlocListener no avisa del estado inicial: se revisa al montar.
    if (widget.isLoading(context.read<B>().state)) showLoadingDialog();
  }

  void _sync(bool loading) =>
      loading ? showLoadingDialog() : hideLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      listenWhen: (prev, curr) =>
          widget.isLoading(prev) != widget.isLoading(curr),
      listener: (_, state) => _sync(widget.isLoading(state)),
      child: widget.child,
    );
  }
}
