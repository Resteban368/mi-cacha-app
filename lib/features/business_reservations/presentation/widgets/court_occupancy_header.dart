import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/court_occupancy.dart';

/// Encabezado de una cancha en la vista "Por cancha": nombre, cuántas
/// reservas tiene y, si hay [occupancy], la barra de ocupación del día.
class CourtOccupancyHeader extends StatelessWidget {
  const CourtOccupancyHeader({
    super.key,
    required this.name,
    required this.count,
    this.occupancy,
  });

  final String name;
  final int count;
  final CourtOccupancy? occupancy;

  static String _hours(int minutes) =>
      AppFormatters.duration(Duration(minutes: minutes));

  @override
  Widget build(BuildContext context) {
    final o = occupancy;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLg.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                count == 1 ? '1 reserva' : '$count reservas',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (o != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Ocupación de $name',
                    value: '${(o.fraction * 100).round()}%',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        key: Key('occupancy-$name'),
                        value: o.isClosed ? 0 : o.fraction,
                        minHeight: 8,
                        backgroundColor: AppColors.slate200,
                        color: AppColors.brandTeal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  o.isClosed ? '—' : '${(o.fraction * 100).round()}%',
                  style: AppTypography.labelLg.copyWith(
                    color: AppColors.brandTeal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              o.isClosed
                  ? 'Cerrada este día'
                  : '${_hours(o.bookedMinutes)} de '
                        '${_hours(o.openMinutes)} abiertas',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
