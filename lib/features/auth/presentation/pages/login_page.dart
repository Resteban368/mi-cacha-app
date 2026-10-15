import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/login_bloc.dart';
import '../widgets/login_access_card.dart';
import '../widgets/login_hero.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  static const _maxContentWidth = 480.0;

  /// Desde este ancho (y [_wideMinHeight] de alto) el hero pasa a ser un
  /// panel a la izquierda y los accesos se centran a la derecha.
  static const _wideBreakpoint = 900.0;
  static const _wideMinHeight = 560.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide =
        size.width >= _wideBreakpoint && size.height >= _wideMinHeight;

    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        switch (state.status) {
          case LoginStatus.success:
            // TODO: confirmar ruta de destino post-login.
            context.go(AppRoutes.home);
          case LoginStatus.failure:
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('No pudimos iniciar sesión. Intenta de nuevo.'),
                ),
              );
          case LoginStatus.initial || LoginStatus.loading:
            break;
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: isWide ? const _WideLayout() : _narrowLayout(size.height),
        ),
      ),
    );
  }

  Widget _narrowLayout(double screenHeight) {
    // Hero: 60% del alto, acotado entre 430 y 520 como en el diseño.
    final heroHeight = (screenHeight * 0.6).clamp(430.0, 520.0);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LoginHero(height: heroHeight),
              // La tarjeta se superpone 24px sobre el hero.
              Transform.translate(
                offset: const Offset(0, -24),
                child: const SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AccessCard(),
                        SizedBox(height: 16),
                        _VenueModeHint(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Web/escritorio: hero como panel a la izquierda (todo el alto) y accesos
/// centrados a la derecha.
class _WideLayout extends StatelessWidget {
  const _WideLayout();

  static const _formWidth = 420.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(
          flex: 11,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: LoginHero(
              large: true,
              borderRadius: BorderRadius.all(Radius.circular(32)),
            ),
          ),
        ),
        Expanded(
          flex: 9,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _formWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Te damos la bienvenida',
                        style: AppTypography.headlineLg.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Elige cómo quieres ingresar para reservar tu '
                        'próxima cancha.',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _AccessCard(),
                      const SizedBox(height: 16),
                      const _VenueModeHint(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      buildWhen: (prev, curr) =>
          prev.isLoading != curr.isLoading || prev.method != curr.method,
      builder: (context, state) => LoginAccessCard(
        loadingMethod: state.isLoading ? state.method : null,
        onMethodSelected: (method) =>
            context.read<LoginBloc>().add(LoginRequested(method)),
      ),
    );
  }
}

class _VenueModeHint extends StatelessWidget {
  const _VenueModeHint();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(
          '¿Administras un complejo deportivo?',
          style: AppTypography.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        TextButton(
          // push: el login de jugador queda debajo y "atrás" regresa a él.
          onPressed: () => context.push(AppRoutes.businessLogin),
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            foregroundColor: AppColors.brandTeal,
            textStyle: AppTypography.labelMd.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Modo Centro'),
        ),
      ],
    );
  }
}
