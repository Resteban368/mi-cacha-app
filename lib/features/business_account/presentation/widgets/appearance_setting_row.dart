import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/appearance/appearance_cubit.dart';
import '../../../../core/appearance/appearance_mode.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'account_card.dart';

/// Fila "Apariencia": claro, oscuro o el modo del sistema. Se guarda en el
/// dispositivo.
class AppearanceSettingRow extends StatelessWidget {
  const AppearanceSettingRow({super.key});

  static IconData _icon(AppearanceMode mode) => switch (mode) {
    AppearanceMode.system => Icons.brightness_auto_outlined,
    AppearanceMode.light => Icons.light_mode_outlined,
    AppearanceMode.dark => Icons.dark_mode_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppearanceCubit>().state;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AccountIconBox(
                icon: _icon(mode),
                background: AppColors.brandTealLight,
                foreground: AppColors.brandTeal,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apariencia',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'Modo claro, oscuro o el del dispositivo',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<AppearanceMode>(
            key: const Key('appearance-selector'),
            showSelectedIcon: false,
            segments: [
              for (final option in const [
                AppearanceMode.light,
                AppearanceMode.dark,
                AppearanceMode.system,
              ])
                ButtonSegment(
                  value: option,
                  icon: Icon(_icon(option), size: 18),
                  label: Text(
                    option.label,
                    key: Key('appearance-${option.storageCode}'),
                  ),
                ),
            ],
            selected: {mode},
            onSelectionChanged: (selection) =>
                context.read<AppearanceCubit>().select(selection.single),
          ),
        ],
      ),
    );
  }
}
