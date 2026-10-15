import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/reservation.dart';
import 'sport_style.dart';

/// Piezas compartidas por las tarjetas de reserva.

class CourtChip extends StatelessWidget {
  const CourtChip({super.key, required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            reservation.sport.icon,
            size: 14,
            color: reservation.sport.color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              reservation.courtName,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSm.copyWith(color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botones redondos de llamada y WhatsApp.
class ContactActions extends StatelessWidget {
  const ContactActions({
    super.key,
    required this.reservation,
    this.size = 32,
    this.callBackground = AppColors.surfaceContainer,
    this.whatsappAlpha = 0.15,
  });

  final Reservation reservation;
  final double size;
  final Color callBackground;
  final double whatsappAlpha;

  @override
  Widget build(BuildContext context) {
    final name = reservation.customerName.split(' ').first;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundAction(
          size: size,
          icon: Icons.call_outlined,
          background: callBackground,
          foreground: AppColors.onSurface,
          tooltip: 'Llamar a $name',
          // TODO: abrir marcador con tel:${reservation.phone}.
          onTap: () {},
        ),
        SizedBox(width: size > 32 ? 6 : 4),
        _RoundAction(
          size: size,
          icon: Icons.chat_outlined,
          background: AppColors.whatsapp.withValues(alpha: whatsappAlpha),
          foreground: AppColors.whatsappDark,
          tooltip: 'WhatsApp $name',
          // TODO: abrir wa.me con el teléfono del cliente.
          onTap: () {},
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.size,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.tooltip,
    required this.onTap,
  });

  final double size;
  final IconData icon;
  final Color background;
  final Color foreground;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              size: size / 2,
              color: foreground,
              semanticLabel: tooltip,
            ),
          ),
        ),
      ),
    );
  }
}

/// Píldora de estado (Completada, No asistió, Confirmada).
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 2),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: foreground,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta pequeña "Pagada".
class PaidTag extends StatelessWidget {
  const PaidTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brandTealLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Pagada',
        style: AppTypography.labelSm.copyWith(
          color: AppColors.statusPaid,
          fontSize: 10,
        ),
      ),
    );
  }
}

/// Tarjeta blanca con franja de color a la izquierda.
class StripedCard extends StatelessWidget {
  const StripedCard({
    super.key,
    required this.stripeColor,
    required this.child,
    this.stripeWidth = 6,
    this.radius = 12,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 12, 12),
    this.elevated = false,
  });

  final Color stripeColor;
  final Widget child;
  final double stripeWidth;
  final double radius;
  final EdgeInsets padding;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevated
            ? const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 6,
                  offset: Offset(0, 4),
                  spreadRadius: -1,
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: stripeWidth,
            child: ColoredBox(color: stripeColor),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
