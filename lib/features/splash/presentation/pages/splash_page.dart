import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/start_destination.dart';
import '../bloc/splash_bloc.dart';
import '../widgets/bouncing_dots_loader.dart';
import '../widgets/brand_logo.dart';
import '../widgets/court_watermark.dart';
import '../widgets/version_badge.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Respeta "reducir movimiento" del sistema.
    final animate = !MediaQuery.disableAnimationsOf(context);

    return BlocListener<SplashBloc, SplashState>(
      listenWhen: (prev, curr) =>
          prev.destination == null && curr.destination != null,
      listener: (context, state) => context.go(switch (state.destination!) {
        StartDestination.home => AppRoutes.home,
        StartDestination.businessHome => AppRoutes.businessReservations,
        StartDestination.login => AppRoutes.login,
      }),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.brandTealDeep,
        ),
        child: Scaffold(
          backgroundColor: AppColors.brandTealDeep,
          body: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.brandTeal,
                      AppColors.primary,
                      AppColors.brandTealDeep,
                    ],
                  ),
                ),
              ),
              const CourtWatermark(),
              // Brillo ambiental detrás del logo.
              Center(
                child: IgnorePointer(
                  child: Container(
                    width: 256,
                    height: 256,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandTealGlow.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 64,
                          spreadRadius: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BrandLogo(animate: animate),
                            const SizedBox(height: 24),
                            Text(
                              'Mi Cancha',
                              textAlign: TextAlign.center,
                              style: AppTypography.displayLgMobile.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w800,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x26000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BouncingDotsLoader(animate: animate),
                          const SizedBox(height: 16),
                          BlocSelector<SplashBloc, SplashState, String>(
                            selector: (state) => state.version,
                            builder: (_, version) => AnimatedOpacity(
                              opacity: version.isEmpty ? 0 : 1,
                              duration: const Duration(milliseconds: 250),
                              child: VersionBadge(version: version),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
