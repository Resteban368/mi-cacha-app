import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/auth_method.dart';
import 'auth_button.dart';

/// Tarjeta inferior con los accesos (Google, Apple, correo) y textos legales.
class LoginAccessCard extends StatelessWidget {
  const LoginAccessCard({
    super.key,
    required this.onMethodSelected,
    this.loadingMethod,
  });

  final ValueChanged<AuthMethod> onMethodSelected;

  /// Método con inicio de sesión en curso; deshabilita el resto.
  final AuthMethod? loadingMethod;

  @override
  Widget build(BuildContext context) {
    final busy = loadingMethod != null;
    VoidCallback? handler(AuthMethod method) =>
        busy ? null : () => onMethodSelected(method);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 50,
            offset: Offset(0, 25),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          AuthButton(
            label: 'Continuar con Google',
            leading: SvgPicture.asset(AppAssets.googleIcon, width: 20),
            backgroundColor: AppColors.surfaceContainerLow,
            foregroundColor: AppColors.onSurface,
            loading: loadingMethod == AuthMethod.google,
            onPressed: handler(AuthMethod.google),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AuthButton(
            label: 'Continuar con Apple',
            leading: SvgPicture.asset(
              AppAssets.appleIcon,
              width: 20,
              colorFilter: ColorFilter.mode(
                AppColors.inverseOnSurface,
                BlendMode.srcIn,
              ),
            ),
            backgroundColor: AppColors.inverseSurface,
            foregroundColor: AppColors.inverseOnSurface,
            loading: loadingMethod == AuthMethod.apple,
            onPressed: handler(AuthMethod.apple),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 6,
                offset: Offset(0, 4),
                spreadRadius: -1,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _OrDivider(),
          const SizedBox(height: 16),
          AuthButton(
            label: 'Continuar con correo electrónico',
            leading: Icon(
              Icons.mail_outline,
              size: 20,
              color: AppColors.brandTeal,
            ),
            height: 50,
            centered: true,
            backgroundColor: AppColors.surfaceTealSubtle,
            foregroundColor: AppColors.brandTeal,
            loading: loadingMethod == AuthMethod.email,
            onPressed: handler(AuthMethod.email),
          ),
          const SizedBox(height: 20),
          const _LegalNotice(),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(height: 1, color: AppColors.surfaceContainerHigh),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o',
            style: AppTypography.bodySm.copyWith(color: AppColors.outline),
          ),
        ),
        Expanded(
          child: Divider(height: 1, color: AppColors.surfaceContainerHigh),
        ),
      ],
    );
  }
}

class _LegalNotice extends StatelessWidget {
  const _LegalNotice();

  @override
  Widget build(BuildContext context) {
    final base = AppTypography.bodySm.copyWith(
      color: AppColors.onSurfaceVariant,
      height: 1.6,
    );
    final link = base.copyWith(
      color: AppColors.brandTeal,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.brandTeal,
    );

    // TODO: enlazar a los documentos legales cuando estén publicados.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            const TextSpan(text: 'Al continuar aceptas los '),
            TextSpan(text: 'Términos y condiciones', style: link),
            const TextSpan(text: ' y la '),
            TextSpan(text: 'Política de tratamiento de datos', style: link),
            const TextSpan(text: '.'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
