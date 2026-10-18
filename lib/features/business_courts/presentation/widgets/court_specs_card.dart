import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/court.dart';

/// Superficie (tipo de grama o piso), medidas y formato de la cancha.
/// Todo es opcional: el negocio lo completa cuando quiera.
class CourtSpecsCard extends StatelessWidget {
  const CourtSpecsCard({
    super.key,
    required this.surfaces,
    required this.selectedSurface,
    required this.onSurfaceChanged,
    required this.lengthController,
    required this.widthController,
    required this.playersController,
    this.sportChosen = true,
  });

  /// Superficies que aplican al deporte elegido.
  final List<CourtSurfaceRef> surfaces;
  final String? selectedSurface;

  /// `null` = sin indicar.
  final ValueChanged<CourtSurfaceRef?> onSurfaceChanged;
  final TextEditingController lengthController;
  final TextEditingController widthController;
  final TextEditingController playersController;

  /// Sin deporte no se sabe qué superficies ofrecer.
  final bool sportChosen;

  /// Hasta 3 enteros y 2 decimales, con punto o coma.
  static final metersFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'^\d{0,3}([.,]\d{0,2})?'),
  );

  @override
  Widget build(BuildContext context) {
    final hintStyle = AppTypography.bodySm.copyWith(
      color: AppColors.onSurfaceVariant,
      fontSize: 12,
    );
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
          Text(
            'SUPERFICIE Y MEDIDAS',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Opcional. Ayuda a tus clientes a elegir la cancha.',
            style: hintStyle,
          ),
          const SizedBox(height: 12),
          Text(
            'Tipo de superficie',
            style: AppTypography.labelLg.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          if (!sportChosen)
            Text('Elige el deporte para ver las superficies.', style: hintStyle)
          else if (surfaces.isEmpty)
            Text('No hay superficies disponibles por ahora.', style: hintStyle)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final surface in surfaces)
                  ChoiceChip(
                    key: Key('court-surface-${surface.code}'),
                    label: Text(surface.name),
                    selected: surface.code == selectedSurface,
                    showCheckmark: false,
                    selectedColor: AppColors.brandTealLight,
                    labelStyle: AppTypography.labelMd.copyWith(
                      color: surface.code == selectedSurface
                          ? AppColors.brandTealDeep
                          : AppColors.onSurfaceVariant,
                      fontWeight: surface.code == selectedSurface
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: surface.code == selectedSurface
                          ? AppColors.brandTeal
                          : AppColors.surfaceContainerHighest,
                    ),
                    // Tocar la elegida la quita.
                    onSelected: (selected) =>
                        onSurfaceChanged(selected ? surface : null),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  key: const Key('court-length'),
                  controller: lengthController,
                  label: 'Largo (m)',
                  prefixIcon: Icons.straighten_rounded,
                  hintText: 'Ej: 42',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [metersFormatter],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  key: const Key('court-width'),
                  controller: widthController,
                  label: 'Ancho (m)',
                  prefixIcon: Icons.straighten_rounded,
                  hintText: 'Ej: 25',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [metersFormatter],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Indica las dos medidas o ninguna.', style: hintStyle),
          const SizedBox(height: 14),
          AppTextField(
            key: const Key('court-players'),
            controller: playersController,
            label: 'Jugadores por equipo',
            prefixIcon: Icons.groups_outlined,
            hintText: 'Ej: 5 para fútbol 5',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
          ),
        ],
      ),
    );
  }
}
