import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/court.dart';
import 'court_summaries.dart';

/// Partes de una cancha que se pueden copiar a una nueva.
enum CourtCopyPart { schedule, pricing, rates }

typedef CourtCopy = ({Court court, Set<CourtCopyPart> parts});

/// Elige de qué cancha copiar y qué partes (por defecto todas). Diálogo en
/// web y hoja inferior en el celular; `null` si se canceló.
Future<CourtCopy?> showCopyFromCourtDialog(
  BuildContext context, {
  required List<Court> courts,
  Court? initial,
}) {
  final content = _CopyFromCourt(courts: courts, initial: initial);
  if (MediaQuery.sizeOf(context).width >= 600) {
    return showDialog<CourtCopy>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
          child: content,
        ),
      ),
    );
  }
  return showModalBottomSheet<CourtCopy>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: content,
    ),
  );
}

class _CopyFromCourt extends StatefulWidget {
  const _CopyFromCourt({required this.courts, required this.initial});

  final List<Court> courts;
  final Court? initial;

  @override
  State<_CopyFromCourt> createState() => _CopyFromCourtState();
}

class _CopyFromCourtState extends State<_CopyFromCourt> {
  late Court _court = widget.initial ?? widget.courts.first;
  final _parts = {...CourtCopyPart.values};

  void _toggle(CourtCopyPart part, bool on) =>
      setState(() => on ? _parts.add(part) : _parts.remove(part));

  /// Sin tarifas en la cancha elegida no hay nada que copiar en esa parte.
  Set<CourtCopyPart> get _effectiveParts => {
    for (final part in _parts)
      if (part != CourtCopyPart.rates || _court.rates.isNotEmpty) part,
  };

  @override
  Widget build(BuildContext context) {
    final label = AppTypography.labelMd.copyWith(
      color: AppColors.onSurfaceVariant,
      letterSpacing: 0.5,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            'Copiar de otra cancha',
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('CANCHA', style: label),
                const SizedBox(height: 4),
                RadioGroup<String>(
                  groupValue: _court.id,
                  onChanged: (id) => setState(
                    () => _court = widget.courts.firstWhere((c) => c.id == id),
                  ),
                  child: Column(
                    children: [
                      for (final court in widget.courts)
                        RadioListTile<String>(
                          value: court.id,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.brandTeal,
                          title: Text(court.name),
                          subtitle: Text(
                            '${CourtSummaries.sport(court.sport)} · '
                            '${CourtSummaries.schedule(court.schedules)}',
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('QUÉ COPIAR', style: label),
                const SizedBox(height: 4),
                _PartTile(
                  title: 'Horario semanal',
                  detail: CourtSummaries.schedule(_court.schedules),
                  value: _parts.contains(CourtCopyPart.schedule),
                  onChanged: (on) => _toggle(CourtCopyPart.schedule, on),
                ),
                _PartTile(
                  title: 'Precio base y duración del turno',
                  detail: CourtSummaries.pricing(_court),
                  value: _parts.contains(CourtCopyPart.pricing),
                  onChanged: (on) => _toggle(CourtCopyPart.pricing, on),
                ),
                _PartTile(
                  title: 'Tarifas por franja',
                  detail: CourtSummaries.rates(_court.rates.length),
                  value:
                      _court.rates.isNotEmpty &&
                      _parts.contains(CourtCopyPart.rates),
                  onChanged: _court.rates.isEmpty
                      ? null
                      : (on) => _toggle(CourtCopyPart.rates, on),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reemplaza lo que hayas cargado en esas partes del '
                  'formulario. Nombre, deporte y fotos no se copian.',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                key: const Key('copy-court-confirm'),
                onPressed: _effectiveParts.isEmpty
                    ? null
                    : () => Navigator.of(
                        context,
                      ).pop((court: _court, parts: _effectiveParts)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: const Text('Copiar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PartTile extends StatelessWidget {
  const _PartTile({
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.brandTeal,
      title: Text(title),
      subtitle: Text(detail),
    );
  }
}
