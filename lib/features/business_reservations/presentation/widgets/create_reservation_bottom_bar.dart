import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';

/// Barra de confirmación: resumen (cancha · día · horario), total estimado,
/// lo que falta completar y el botón "Confirmar reserva".
class CreateReservationBottomBar extends StatelessWidget {
  const CreateReservationBottomBar({
    super.key,
    required this.summary,
    required this.total,
    required this.missing,
    required this.isLoading,
    required this.onConfirm,
    this.inline = false,
  });

  final String summary;
  final int? total;
  final List<String> missing;
  final bool isLoading;
  final VoidCallback? onConfirm;

  /// En web va dentro de la columna derecha (sin sombra ni margen seguro).
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                summary,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              total == null ? '—' : AppFormatters.cop(total!),
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Falta: ${missing.join(', ')}',
            key: const Key('reservation-missing'),
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            key: const Key('confirm-reservation'),
            onPressed: isLoading ? null : onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              disabledBackgroundColor: AppColors.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            icon: isLoading
                ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  )
                : const Icon(Icons.check_circle, color: AppColors.accentLime),
            label: Text(isLoading ? 'Reservando…' : 'Confirmar reserva'),
          ),
        ),
      ],
    );
    if (inline) return content;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.97),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F8B7A),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      child: content,
    );
  }
}
