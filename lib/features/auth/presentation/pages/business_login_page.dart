import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/auth_failure.dart';
import '../bloc/business_login/business_login_bloc.dart';
import '../widgets/business_login_form.dart';
import '../widgets/business_login_header.dart';

/// Inicio de sesión para administradores de negocio ("Modo Centro").
class BusinessLoginPage extends StatefulWidget {
  const BusinessLoginPage({super.key, this.sessionExpired = false});

  /// Se llegó aquí porque la API rechazó el token (401): se avisa al entrar.
  final bool sessionExpired;

  @override
  State<BusinessLoginPage> createState() => _BusinessLoginPageState();
}

class _BusinessLoginPageState extends State<BusinessLoginPage> {
  static const _maxContentWidth = 412.0;

  /// Desde este ancho (y [_wideMinHeight] de alto) la cabecera pasa a ser un
  /// panel a la izquierda y el formulario se centra a la derecha.
  static const _wideBreakpoint = 900.0;
  static const _wideMinHeight = 560.0;

  /// "Volver" solo existe si el acceso de jugadores está habilitado.
  VoidCallback? _onBack(BuildContext context) =>
      FeatureFlags.playerAccess ? () => _backToPlayerLogin(context) : null;

  /// Si se llegó con "Modo Centro" vuelve con pop; si se entró directo
  /// (p. ej. URL en web) no hay historial y se reemplaza por el login.
  void _backToPlayerLogin(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  static String _failureMessage(AuthFailure? failure) => switch (failure) {
    AuthFailure.invalidCredentials => 'Correo o contraseña incorrectos.',
    AuthFailure.notBusinessAccount =>
      'Esta cuenta no es de administrador de negocio.',
    AuthFailure.network =>
      'Sin conexión con el servidor. Revisa tu internet e intenta de nuevo.',
    AuthFailure.server ||
    null => 'No pudimos iniciar sesión. Intenta de nuevo en unos minutos.',
  };

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    if (widget.sessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showMessage(
            context,
            'Tu sesión venció. Ingresa de nuevo para continuar.',
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide =
        size.width >= _wideBreakpoint && size.height >= _wideMinHeight;

    return BlocListener<BusinessLoginBloc, BusinessLoginState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        switch (state.status) {
          case BusinessLoginStatus.success:
            context.go(AppRoutes.businessReservations);
          case BusinessLoginStatus.failure:
            _showMessage(context, _failureMessage(state.failure));
          case BusinessLoginStatus.initial || BusinessLoginStatus.loading:
            break;
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: isWide ? Colors.white : AppColors.surface,
          body: isWide
              ? _WideLayout(onBack: _onBack(context))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _maxContentWidth,
                    ),
                    child: ColoredBox(
                      color: AppColors.brandTeal,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: BusinessLoginHeader(
                              onBack: _onBack(context),
                            ),
                          ),
                          // La hoja blanca ocupa el resto del alto disponible.
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: _LoginSheet(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Web/escritorio: cabecera teal como panel a la izquierda (todo el alto) y
/// formulario centrado a la derecha.
class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.onBack});

  static const _formWidth = 420.0;

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 11,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: ColoredBox(
                color: AppColors.brandTeal,
                child: BusinessLoginHeader(onBack: onBack, panel: true),
              ),
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
                  child: const _LoginContent(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginSheet extends StatelessWidget {
  const _LoginSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x40042823),
            blurRadius: 40,
            offset: Offset(0, -12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate200,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Expanded(child: _LoginContent(pinFooterToBottom: true)),
          ],
        ),
      ),
    );
  }
}

/// Bienvenida, formulario y pie de registro; compartido por móvil y web.
class _LoginContent extends StatelessWidget {
  const _LoginContent({this.pinFooterToBottom = false});

  /// En la hoja móvil el pie baja hasta el borde inferior; en web va a
  /// continuación del formulario.
  final bool pinFooterToBottom;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Bienvenido de nuevo',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ingresa para administrar tus canchas y reservas',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            height: 1.6,
            color: AppColors.slate500,
          ),
        ),
        const SizedBox(height: 24),
        BlocBuilder<BusinessLoginBloc, BusinessLoginState>(
          buildWhen: (prev, curr) => prev.isLoading != curr.isLoading,
          builder: (context, state) => BusinessLoginForm(
            loading: state.isLoading,
            onSubmit: (email, password) => context
                .read<BusinessLoginBloc>()
                .add(BusinessLoginSubmitted(email: email, password: password)),
          ),
        ),
        const SizedBox(height: 16),
        if (pinFooterToBottom) const Spacer(),
        const SizedBox(height: 14),
        const _RegisterBusinessFooter(),
      ],
    );
  }
}

class _RegisterBusinessFooter extends StatelessWidget {
  const _RegisterBusinessFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.slate100)),
      ),
      child: Column(
        children: [
          Text(
            '¿Quieres registrar tu negocio en Mi Cancha?',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: AppColors.emerald50,
            shape: StadiumBorder(
              side: BorderSide(
                color: AppColors.emerald200.withValues(alpha: 0.8),
              ),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              // TODO: abrir chat de WhatsApp de ventas (solo diseño).
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(AppAssets.whatsappIcon, width: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Escríbenos por WhatsApp',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.emerald800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
