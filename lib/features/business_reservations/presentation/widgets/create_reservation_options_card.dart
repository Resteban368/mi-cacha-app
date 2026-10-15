import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/new_reservation.dart';
import 'reservation_section_card.dart';

/// Datos adicionales: equipo o detalle, etiqueta, nota y si es recurrente.
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

  @override
  Widget build(BuildContext context) {
    return ReservationSectionCard(
      icon: Icons.tune,
      title: 'Opciones adicionales',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            key: const Key('reservation-detail'),
            controller: detailController,
            label: 'Equipo o detalle (opcional)',
            prefixIcon: Icons.groups_outlined,
            hintText: 'Ej. Equipo Los Halcones',
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NewReservation.maxDetail),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            key: const Key('reservation-tag'),
            controller: tagController,
            label: 'Etiqueta (opcional)',
            prefixIcon: Icons.sell_outlined,
            hintText: 'Ej. Torneo',
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NewReservation.maxTag),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            key: const Key('reservation-note'),
            controller: noteController,
            label: 'Nota de contacto (opcional)',
            prefixIcon: Icons.sticky_note_2_outlined,
            hintText: 'Ej. Llega 10 min antes',
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NewReservation.maxContactNote),
            ],
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: isRecurring,
            onChanged: onRecurringChanged,
            activeTrackColor: AppColors.primary,
            title: Text(
              'Reserva recurrente',
              style: AppTypography.labelLg.copyWith(color: AppColors.onSurface),
            ),
            subtitle: Text(
              'Se marca como cliente fijo en la agenda.',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
