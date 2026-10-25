import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';

/// "Resumen del turno" (web): tarjeta oscura con cancha, horario, cliente,
/// estado del pago, total y el botón "Confirmar e ingresar reserva".
class CreateReservationSummaryCard extends StatelessWidget {
  const CreateReservationSummaryCard({
    super.key,
    required this.title,
    required this.schedule,
    required this.customer,
    required this.payment,
    required this.total,
    required this.missing,
    required this.isLoading,
    required this.onConfirm,
    this.compact = false,
  });

  /// "Fútbol · Cancha c1".
  final String title;
  final String? schedule;
  final String? customer;
  final String payment;
  final int? total;
  final List<String> missing;
  final bool isLoading;
  final VoidCallback? onConfirm;

  /// Con poca altura solo muestra título, total y el botón, para no tapar
  /// el resto de la columna.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String? value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.slate400,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? '—',
              textAlign: TextAlign.end,
              style: AppTypography.bodySm.copyWith(
                color: color ?? AppColors.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      key: const Key('reservation-confirm-panel'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESUMEN DEL TURNO',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.accentLime,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      title,
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.onPrimary,
                        fontSize: compact ? 13 : 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (compact) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total estimado',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.slate400,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      total == null ? '—' : AppFormatters.cop(total!),
                      style: AppTypography.labelLg.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ] else
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.event_available,
                    size: 16,
                    color: AppColors.accentLime,
                  ),
                ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: AppColors.onPrimary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Column(
                children: [
                  row('Fecha y hora', schedule),
                  row('Cliente titular', customer),
                  row('Estado de pago', payment, color: AppColors.accentLime),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Total estimado',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.slate400,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  total == null ? '—' : AppFormatters.cop(total!),
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'Falta: ${missing.join(', ')}',
              key: const Key('reservation-missing'),
              style: AppTypography.bodySm.copyWith(
                color: AppColors.slate400,
                fontSize: 10,
              ),
            ),
          ],
          SizedBox(height: compact ? 6 : 8),
          SizedBox(
            height: compact ? 38 : 42,
            child: FilledButton.icon(
              key: const Key('confirm-reservation'),
              onPressed: isLoading ? null : onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentLime,
                foregroundColor: AppColors.onSecondaryFixed,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                disabledBackgroundColor: AppColors.onPrimary.withValues(
                  alpha: 0.12,
                ),
                disabledForegroundColor: AppColors.slate400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: AppTypography.labelLg.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              icon: isLoading
                  ? SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.slate400,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 17),
              label: Text(
                isLoading ? 'Reservando…' : 'Confirmar e ingresar reserva',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
