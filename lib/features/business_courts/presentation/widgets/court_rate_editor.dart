import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/cop_input_formatter.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/court_rate.dart';
import '../../domain/entities/court_time.dart';
import '../../domain/entities/week_day.dart';
import 'court_time_picker.dart';

/// Abre el formulario de una tarifa: diálogo en web, hoja inferior en el
/// celular. Devuelve la tarifa o `null` si se canceló. [others] son las
/// demás tarifas, para avisar si se cruzan.
Future<CourtRate?> showCourtRateEditor(
  BuildContext context, {
  CourtRate? initial,
  List<CourtRate> others = const [],
}) {
  final editor = _RateEditor(initial: initial, others: others);
  if (MediaQuery.sizeOf(context).width >= 600) {
    return showDialog<CourtRate>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: editor,
        ),
      ),
    );
  }
  return showModalBottomSheet<CourtRate>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => editor,
  );
}

class _RateEditor extends StatefulWidget {
  const _RateEditor({required this.initial, required this.others});

  final CourtRate? initial;
  final List<CourtRate> others;

  @override
  State<_RateEditor> createState() => _RateEditorState();
}

class _RateEditorState extends State<_RateEditor> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _price = TextEditingController(
    text: CopInputFormatter.format(widget.initial?.pricePerHour ?? 0),
  );
  late Set<WeekDay> _days = {...?widget.initial?.days};
  late CourtTime _start = widget.initial?.start ?? const CourtTime(18);
  late CourtTime _end = widget.initial?.end ?? const CourtTime(22);
  String? _error;

  static const _presets = {
    'L-V': {
      WeekDay.monday,
      WeekDay.tuesday,
      WeekDay.wednesday,
      WeekDay.thursday,
      WeekDay.friday,
    },
    'Fin de semana': {WeekDay.saturday, WeekDay.sunday},
    'Todos': {...WeekDay.values},
  };

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final price = CopInputFormatter.parse(_price.text);
    final String? error;
    if (name.isEmpty) {
      error = 'Ponle un nombre a la tarifa.';
    } else if (price <= 0) {
      error = 'Ingresa el precio por hora.';
    } else if (_days.isEmpty) {
      error = 'Elige al menos un día.';
    } else {
      final rate = CourtRate(
        name: name,
        pricePerHour: price,
        days: _days,
        start: _start,
        end: _end,
      );
      final clash = widget.others.where(rate.overlaps).firstOrNull;
      if (clash == null) {
        Navigator.of(context).pop(rate);
        return;
      }
      error =
          'Se cruza con la tarifa "${clash.name}". Cambia los días o '
          'las horas.';
    }
    setState(() => _error = error);
  }

  Future<void> _pick({required bool start}) async {
    final picked = await pickCourtTime(
      context,
      initial: start ? _start : _end,
      helpText: start ? 'Inicio de la franja' : 'Fin de la franja',
    );
    if (picked == null) return;
    setState(() => start ? _start = picked : _end = picked);
  }

  @override
  Widget build(BuildContext context) {
    final crossesMidnight = _end.inMinutes <= _start.inMinutes;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initial == null ? 'Nueva tarifa' : 'Editar tarifa',
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            key: const Key('rate-name'),
            controller: _name,
            label: 'Nombre',
            prefixIcon: Icons.label_outline,
            hintText: 'Ej: Nocturna L-V',
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [
              LengthLimitingTextInputFormatter(CourtRate.maxNameLength),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            key: const Key('rate-price'),
            controller: _price,
            label: 'Precio por hora',
            prefixIcon: Icons.attach_money,
            hintText: 'Ej: 90.000',
            keyboardType: TextInputType.number,
            inputFormatters: const [CopInputFormatter()],
          ),
          const SizedBox(height: 16),
          Text(
            'DÍAS',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final day in WeekDay.values)
                FilterChip(
                  label: Text(day.shortLabel),
                  selected: _days.contains(day),
                  showCheckmark: false,
                  selectedColor: AppColors.brandTeal,
                  labelStyle: AppTypography.labelMd.copyWith(
                    color: _days.contains(day)
                        ? AppColors.onPrimary
                        : AppColors.onSurface,
                  ),
                  onSelected: (on) => setState(
                    () => _days = on
                        ? {..._days, day}
                        : ({..._days}..remove(day)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              for (final MapEntry(key: label, value: days) in _presets.entries)
                TextButton(
                  onPressed: () => setState(() => _days = {...days}),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandTeal,
                    textStyle: AppTypography.labelMd,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(label),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'HORARIO',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CourtTimeButton(
                time: _start,
                semanticLabel: 'Inicio ${_start.label}',
                onPressed: () => _pick(start: true),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('a'),
              ),
              CourtTimeButton(
                time: _end,
                semanticLabel: 'Fin ${_end.label}',
                onPressed: () => _pick(start: false),
              ),
              if (crossesMidnight) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'termina al día siguiente',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            Text(
              error,
              style: AppTypography.bodySm.copyWith(color: AppColors.statusDue),
            ),
          ],
          const SizedBox(height: 20),
          // Si no caben en una fila, se apilan (pantallas angostas).
          OverflowBar(
            alignment: MainAxisAlignment.end,
            overflowAlignment: OverflowBarAlignment.end,
            spacing: 8,
            overflowSpacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                key: const Key('rate-save'),
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: const Text('Guardar tarifa'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
