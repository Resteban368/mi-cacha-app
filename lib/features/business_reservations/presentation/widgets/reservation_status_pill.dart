import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/reservation.dart';

/// Estado de la reserva: Confirmada, Jugada, No asistió o Cancelada.
class ReservationStatusPill extends StatelessWidget {
  const ReservationStatusPill({super.key, required this.status});

  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      ReservationStatus.confirmed => (
        AppColors.brandTealLight,
        AppColors.brandTealDeep,
      ),
      ReservationStatus.completed => (
        AppColors.surfaceContainerHigh,
        AppColors.onSurface,
      ),
      ReservationStatus.noShow || ReservationStatus.cancelled => (
        AppColors.errorContainer,
        AppColors.onErrorContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: AppTypography.labelSm.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
