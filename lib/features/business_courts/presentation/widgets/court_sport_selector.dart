import 'package:flutter/material.dart';

import '../../../../core/domain/entities/sport.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Deporte que se puede elegir al crear una cancha.
class SportOption {
  const SportOption({
    required this.sport,
    required this.name,
    required this.icon,
  });

  final Sport sport;
  final String name;
  final IconData icon;

  /// Código de la API (`PADEL`, `FUTBOL`…).
  String get id => sport.apiCode;
}

/// Los deportes que acepta la API (`FUTBOL`, `PADEL`, `BALONCESTO`,
/// `VOLEIBOL`).
const List<SportOption> kDefaultSportOptions = [
  SportOption(sport: Sport.futbol, name: 'Fútbol', icon: Icons.sports_soccer),
  SportOption(sport: Sport.padel, name: 'Pádel', icon: Icons.sports_tennis),
  SportOption(
    sport: Sport.baloncesto,
    name: 'Baloncesto',
    icon: Icons.sports_basketball,
  ),
  SportOption(
    sport: Sport.voleibol,
    name: 'Voleibol',
    icon: Icons.sports_volleyball,
  ),
];

/// Selector táctil de disciplinas deportivas para la cancha (2 columnas en
/// el celular, 4 cuando hay ancho).
class CourtSportSelector extends StatelessWidget {
  const CourtSportSelector({
    super.key,
    required this.selectedSportId,
    required this.onSportSelected,
    this.options = kDefaultSportOptions,
  });

  final String? selectedSportId;
  final ValueChanged<SportOption> onSportSelected;
  final List<SportOption> options;

  static const _wideWidth = 480.0;

  @override
  Widget build(BuildContext context) {
    final countSelected = selectedSportId == null ? 0 : 1;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DISCIPLINA DEPORTIVA',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Selecciona el deporte de la cancha',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandTealLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  countSelected == 1 ? '1 seleccionado' : '0 seleccionados',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 2 columnas en el celular; 4 en una fila cuando hay ancho (web).
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth >= _wideWidth ? 4 : 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 110,
              ),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selectedSportId == option.id;

                return _SportCard(
                  option: option,
                  isSelected: isSelected,
                  onTap: () => onSportSelected(option),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SportCard extends StatelessWidget {
  const _SportCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final SportOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.brandTeal : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      elevation: isSelected ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.surfaceContainerLowest.withValues(
                              alpha: 0.2,
                            )
                          : AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      option.icon,
                      size: 24,
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.primary,
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.secondaryContainer,
                      size: 20,
                    ),
                ],
              ),
              Text(
                option.name,
                style: AppTypography.headlineSm.copyWith(
                  fontSize: 16,
                  color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
