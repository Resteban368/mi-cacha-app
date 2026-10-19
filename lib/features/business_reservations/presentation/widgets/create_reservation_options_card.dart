import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/new_reservation.dart';
import 'reservation_section_card.dart';

/// "3. Opciones adicionales de la cita": equipo o partido, etiqueta (con
/// atajos), nota y si es recurrente.
class CreateReservationOptionsCard extends StatelessWidget {
  const CreateReservationOptionsCard({
    super.key,
    required this.isRecurring,
    required this.onRecurringChanged,
    required this.detailController,
    required this.tagController,
    required this.noteController,
  });

  final bool isRecurring;
  final ValueChanged<bool> onRecurringChanged;
  final TextEditingController detailController;
  final TextEditingController tagController;
  final TextEditingController noteController;

  /// Etiquetas frecuentes: un toque llena el campo.
  static const quickTags = [
    'Amistoso',
    'Torneo local',
    'Cumpleaños',
    'Escuela',
  ];

  @override
  Widget build(BuildContext context) {
    final detail = AppTextField(
      key: const Key('reservation-detail'),
      controller: detailController,
      label: 'Equipo o partido (opcional)',
      prefixIcon: Icons.groups_outlined,
      hintText: 'Ej. Los Halcones FC vs Barrio Bolívar',
      textCapitalization: TextCapitalization.sentences,
      inputFormatters: [
        LengthLimitingTextInputFormatter(NewReservation.maxDetail),
      ],
    );
    final tag = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const Key('reservation-tag'),
          controller: tagController,
          label: 'Etiqueta / tipo de juego',
          prefixIcon: Icons.sell_outlined,
          hintText: 'Ej. Torneo',
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [
            LengthLimitingTextInputFormatter(NewReservation.maxTag),
          ],
        ),
        const SizedBox(height: 6),
        ListenableBuilder(
          listenable: tagController,
          builder: (context, _) => Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final quick in quickTags)
                _QuickTag(
                  label: quick,
                  selected: tagController.text.trim() == quick,
                  onTap: () => tagController.text =
                      tagController.text.trim() == quick ? '' : quick,
                ),
            ],
          ),
        ),
      ],
    );
    return ReservationSectionCard(
      compact: true,
      icon: Icons.tune,
      title: '3. Opciones adicionales de la cita',
      subtitle: 'Opcional · Para la planilla y logística',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 560
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: detail),
                      const SizedBox(width: 12),
                      Expanded(child: tag),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [detail, const SizedBox(height: 8), tag],
                  ),
          ),
          const SizedBox(height: 8),
          AppTextField(
            key: const Key('reservation-note'),
            controller: noteController,
            label: 'Nota para la recepción o el canchero (opcional)',
            prefixIcon: Icons.sticky_note_2_outlined,
            hintText: 'Ej. Llega 10 min antes; piden petos y balón #5',
            textCapitalization: TextCapitalization.sentences,
            maxLines: 1,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NewReservation.maxContactNote),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: const Icon(
                    Icons.repeat,
                    size: 15,
                    color: AppColors.brandTeal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reserva recurrente / cliente fijo semanal',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.slate900,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Se marca como cliente fijo en la agenda.',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.slate500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.85,
                  child: Switch.adaptive(
                    key: const Key('reservation-recurring'),
                    value: isRecurring,
                    onChanged: onRecurringChanged,
                    activeTrackColor: AppColors.brandTeal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTag extends StatelessWidget {
  const _QuickTag({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandTeal : AppColors.slate100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: Key('quick-tag-$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? AppColors.brandTeal : AppColors.slate200,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.slate600,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
