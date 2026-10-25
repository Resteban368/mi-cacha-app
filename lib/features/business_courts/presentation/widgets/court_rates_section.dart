import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/court_rate.dart';
import '../../domain/entities/week_day.dart';

/// Tarifas por franja: lista con editar/quitar y botón para agregar.
class CourtRatesSection extends StatelessWidget {
  const CourtRatesSection({
    super.key,
    required this.rates,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final List<CourtRate> rates;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  /// `L-V`, `Sáb y Dom`, `Todos los días`…
  static String daysLabel(Set<WeekDay> days) {
    if (days.length == WeekDay.values.length) return 'Todos los días';
    final sorted = days.toList()..sort((a, b) => a.index.compareTo(b.index));
    final consecutive =
        sorted.length > 2 &&
        sorted.last.index - sorted.first.index == sorted.length - 1;
    if (consecutive) {
      return '${sorted.first.shortLabel} a ${sorted.last.shortLabel}';
    }
    return sorted.map((d) => d.shortLabel).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = rates.length < CourtRate.maxRates;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rates.isEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.brandTealLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.payments_outlined,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no has agregado tarifas',
              textAlign: TextAlign.center,
              style: AppTypography.headlineSm.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Son opcionales: sin tarifas se cobra el precio base en todo '
              'el horario. Úsalas para horas pico, noches o fines de semana.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            for (final (i, rate) in rates.indexed) ...[
              if (i > 0) const SizedBox(height: 8),
              _RateTile(
                rate: rate,
                onEdit: () => onEdit(i),
                onRemove: () => onRemove(i),
              ),
            ],
            const SizedBox(height: 12),
          ],
          Center(
            child: FilledButton.icon(
              onPressed: canAdd ? onAdd : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: AppTypography.labelLg.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text('Agregar tarifa'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RateTile extends StatelessWidget {
  const _RateTile({
    required this.rate,
    required this.onEdit,
    required this.onRemove,
  });

  final CourtRate rate;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hours =
        '${rate.start.label} – ${rate.end.label}'
        '${rate.crossesMidnight ? ' (día sig.)' : ''}';
    return Material(
      color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rate.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLg.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CourtRatesSection.daysLabel(rate.days)} · $hours',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${AppFormatters.cop(rate.pricePerHour)}/h',
                style: AppTypography.labelLg.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                tooltip: 'Quitar tarifa ${rate.name}',
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
