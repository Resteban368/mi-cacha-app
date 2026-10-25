import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Tarjeta de sección de "Crear Reserva" (diseño web de Stitch): fondo
/// blanco con borde suave y encabezado con ícono en recuadro, título,
/// subtítulo y a la derecha una insignia o un control ([trailing]).
class ReservationSectionCard extends StatelessWidget {
  const ReservationSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.badge,
    this.trailing,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  /// Insignia a la derecha del título (p. ej. "6 libres").
  final String? badge;

  /// Control a la derecha del encabezado (p. ej. un interruptor). En
  /// pantallas angostas baja debajo del título.
  final Widget? trailing;

  /// Modo compacto para ahorrar espacio vertical en formularios densos.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final heading = Row(
      children: [
        Container(
          padding: EdgeInsets.all(compact ? 6 : 8),
          decoration: BoxDecoration(
            color: AppColors.brandTealLight,
            borderRadius: BorderRadius.circular(compact ? 8 : 10),
          ),
          child: Icon(icon, size: compact ? 18 : 20, color: AppColors.brandTeal),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.slate900,
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle case final subtitle?)
                Text(
                  subtitle,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.slate500,
                    fontSize: compact ? 11 : 12,
                  ),
                ),
            ],
          ),
        ),
        if (badge case final badge?) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.brandTealLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge.toUpperCase(),
              style: AppTypography.labelSm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: AppColors.slate200.withValues(alpha: 0.8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.all(compact ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (trailing case final trailing?)
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth >= 560
                  ? Row(
                      children: [
                        Expanded(child: heading),
                        const SizedBox(width: 12),
                        trailing,
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [heading, const SizedBox(height: 12), trailing],
                    ),
            )
          else
            heading,
          Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 8 : 14),
            child: Divider(height: 1, color: AppColors.slate100),
          ),
          child,
        ],
      ),
    );
  }
}

/// Fila "etiqueta ........ valor" de los resúmenes.
class ReservationAmountRow extends StatelessWidget {
  const ReservationAmountRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasis = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasis;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = emphasis
        ? AppTypography.headlineSm.copyWith(
            color: valueColor ?? AppColors.primary,
            fontWeight: FontWeight.w700,
          )
        : AppTypography.bodyMd.copyWith(
            color: valueColor ?? AppColors.onSurface,
            fontWeight: FontWeight.w600,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Text(value, style: style),
        ],
      ),
    );
  }
}
