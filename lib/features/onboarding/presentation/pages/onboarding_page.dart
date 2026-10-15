import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/onboarding_bloc.dart';
import '../widgets/onboarding_common.dart';
import '../widgets/onboarding_step_availability.dart';
import '../widgets/onboarding_step_booking.dart';
import '../widgets/onboarding_step_discover.dart';

/// Onboarding de 3 pasos en una sola ruta (PageView), para no apilar rutas.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _maxContentWidth = 480.0;

  /// En web los pasos se reparten en dos columnas hasta este ancho.
  static const _maxWideContentWidth = 1200.0;
  static const _transition = Duration(milliseconds: 350);

  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.jumpToPage(page);
    } else {
      _controller.animateToPage(
        page,
        duration: _transition,
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _next() => _goTo(context.read<OnboardingBloc>().state.page + 1);

  void _back() => _goTo(context.read<OnboardingBloc>().state.page - 1);

  void _finish() =>
      context.read<OnboardingBloc>().add(const OnboardingFinished());

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listenWhen: (prev, curr) => !prev.completed && curr.completed,
      // TODO: definir si "Empezar ahora" debe ir a un registro distinto.
      listener: (context, _) => context.go(AppRoutes.login),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.surface,
        ),
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    OnboardingStepLayout.isWide(MediaQuery.sizeOf(context))
                    ? _maxWideContentWidth
                    : _maxContentWidth,
              ),
              child: PageView(
                controller: _controller,
                onPageChanged: (page) => context.read<OnboardingBloc>().add(
                  OnboardingPageChanged(page),
                ),
                children: [
                  OnboardingStepDiscover(onNext: _next, onSkip: _finish),
                  OnboardingStepAvailability(
                    onNext: _next,
                    onBack: _back,
                    onSkip: _finish,
                  ),
                  OnboardingStepBooking(onStart: _finish, onLogin: _finish),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
