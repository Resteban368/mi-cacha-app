import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Etiqueta de sección del formulario del negocio, con texto opcional a la
/// derecha ("Sin fijar", "Para el perfil de reservas").
class BusinessFormLabel extends StatelessWidget {
  const BusinessFormLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: AppTypography.labelMd.copyWith(
        color: AppColors.slate700,
        letterSpacing: 0.6,
      ),
    );
    if (trailing == null) return label;
    // Ambos se ajustan para no desbordar en pantallas angostas o con
    // texto grande de accesibilidad.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(flex: 3, child: label),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: Align(alignment: Alignment.centerRight, child: trailing),
        ),
      ],
    );
  }
}
