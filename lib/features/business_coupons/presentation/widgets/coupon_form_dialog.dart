import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/media/image_upload.dart';
import '../../../../core/media/photo_picker.dart';
import '../../../../core/media/pick_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/coupon.dart';

/// Guarda el cupón con su imagen. `error` deja el diálogo abierto; `warning`
/// significa que el cupón sí se guardó.
typedef CouponSave =
    Future<({String? error, String? warning})> Function(
      CouponDraft draft,
      ImageUpload? image, {
      required bool removeImage,
    });

/// Formulario de cupón (nuevo o editado). Al guardar devuelve `true`; el
/// resultado de la imagen lo muestra [onWarning].
Future<bool> showCouponFormDialog(
  BuildContext context, {
  required CouponSave onSave,
  required PhotoPicker photoPicker,
  required ValueChanged<String> onWarning,
  Coupon? coupon,
  DateTime Function() now = DateTime.now,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _CouponFormDialog(
        coupon: coupon,
        onSave: onSave,
        photoPicker: photoPicker,
        onWarning: onWarning,
        now: now,
      ),
    ) ??
    false;

class _CouponFormDialog extends StatefulWidget {
  const _CouponFormDialog({
    required this.onSave,
    required this.photoPicker,
    required this.onWarning,
    required this.now,
    this.coupon,
  });

  final Coupon? coupon;
  final CouponSave onSave;
  final PhotoPicker photoPicker;
  final ValueChanged<String> onWarning;
  final DateTime Function() now;

  @override
  State<_CouponFormDialog> createState() => _CouponFormDialogState();
}

class _CouponFormDialogState extends State<_CouponFormDialog> {
  late final _name = TextEditingController(text: widget.coupon?.name);
  late final _description = TextEditingController(
    text: widget.coupon?.rewardDescription,
  );
  late final _required = TextEditingController(
    text: '${widget.coupon?.requiredReservations ?? 10}',
  );
  late final _percent = TextEditingController(
    text: widget.coupon?.percent?.toString(),
  );
  late final _max = TextEditingController(
    text: widget.coupon?.maxRedemptions?.toString(),
  );
  late CouponRewardType _type =
      widget.coupon?.rewardType ?? CouponRewardType.freeCourt;
  late DateTime? _expiresOn = widget.coupon?.expiresAt;
  late bool _unlimited = widget.coupon?.maxRedemptions == null;
  ImageUpload? _image;
  bool _removeImage = false;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.coupon != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _required.dispose();
    _percent.dispose();
    _max.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = widget.now();
    final first = DateTime(today.year, today.month, today.day);
    final current = _expiresOn;
    final picked = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: DateTime(today.year + 10),
      initialDate: current != null && !current.isBefore(first)
          ? current
          : first.add(const Duration(days: 30)),
      helpText: 'Último día válido',
    );
    if (picked != null && mounted) setState(() => _expiresOn = picked);
  }

  Future<void> _pickImage() async {
    final image = await pickImageUpload(context, widget.photoPicker);
    if (image == null || !mounted) return;
    setState(() {
      _image = image;
      _removeImage = false;
    });
  }

  Widget _imageField() {
    final picked = _image;
    final current = _removeImage ? null : widget.coupon?.imageUrl;
    final hasImage = picked != null || current != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Imagen (opcional)', style: AppTypography.labelMd),
        const SizedBox(height: 8),
        if (hasImage) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 2,
              child: picked != null
                  ? Image.memory(picked.bytes, fit: BoxFit.cover)
                  : AppNetworkImage(current!),
            ),
          ),
          const SizedBox(height: 4),
        ],
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              key: const Key('coupon-pick-image'),
              onPressed: _saving ? null : _pickImage,
              icon: const Icon(Icons.image_outlined, size: 18),
              label: Text(hasImage ? 'Cambiar imagen' : 'Agregar imagen'),
            ),
            if (hasImage)
              TextButton.icon(
                key: const Key('coupon-remove-image'),
                onPressed: _saving
                    ? null
                    : () => setState(() {
                        _image = null;
                        _removeImage = widget.coupon?.imageUrl != null;
                      }),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Quitar'),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await widget.onSave(
      (
        id: widget.coupon?.id,
        name: _name.text,
        requiredReservations: int.tryParse(_required.text.trim()) ?? 0,
        rewardType: _type,
        percent: int.tryParse(_percent.text.trim()),
        rewardDescription: _description.text,
        expiresOn: _expiresOn,
        maxRedemptions: _unlimited ? null : int.tryParse(_max.text.trim()) ?? 0,
      ),
      _image,
      removeImage: _removeImage,
    );
    if (!mounted) return;
    final error = result.error;
    if (error == null) {
      if (result.warning case final warning?) widget.onWarning(warning);
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final expiresOn = _expiresOn;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      scrollable: true,
      title: Text(_editing ? 'Editar cupón' : 'Nuevo cupón'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('coupon-name'),
              controller: _name,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Cliente frecuente',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('coupon-required'),
              controller: _required,
              enabled: !_editing,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Reservas a llenar',
                helperText: 'Jugadas y pagadas por completo',
              ),
            ),
            const SizedBox(height: 16),
            Text('Tipo de premio', style: AppTypography.labelMd),
            const SizedBox(height: 8),
            SegmentedButton<CouponRewardType>(
              segments: const [
                ButtonSegment(
                  value: CouponRewardType.freeCourt,
                  label: Text('Cancha gratis'),
                ),
                ButtonSegment(
                  value: CouponRewardType.percent,
                  label: Text('Porcentaje'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: _editing
                  ? null
                  : (selection) => setState(() => _type = selection.first),
            ),
            if (_type == CouponRewardType.percent) ...[
              const SizedBox(height: 12),
              TextField(
                key: const Key('coupon-percent'),
                controller: _percent,
                enabled: !_editing,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Porcentaje de descuento',
                  suffixText: '%',
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              key: const Key('coupon-description'),
              controller: _description,
              maxLength: 200,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripción del premio',
                hintText: 'Una hora gratis en cualquier cancha',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            _imageField(),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('coupon-expires-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Tiene fecha de vencimiento'),
              subtitle: Text(
                expiresOn == null
                    ? 'No vence'
                    : 'Válido hasta el ${AppFormatters.mediumDate(expiresOn)}',
              ),
              value: expiresOn != null,
              onChanged: (value) =>
                  value ? _pickDate() : setState(() => _expiresOn = null),
            ),
            if (expiresOn != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event_rounded, size: 18),
                  label: const Text('Cambiar fecha'),
                ),
              ),
            SwitchListTile(
              key: const Key('coupon-unlimited-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Redenciones ilimitadas'),
              subtitle: const Text('Sin tope entre todos los clientes'),
              value: _unlimited,
              onChanged: (value) => setState(() => _unlimited = value),
            ),
            if (!_unlimited)
              TextField(
                key: const Key('coupon-max'),
                controller: _max,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Cantidad de cupones a redimir',
                  helperText: 'En total, entre todos los clientes',
                ),
              ),
            if (_error case final error?) ...[
              const SizedBox(height: 12),
              Text(
                error,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.statusDue,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('coupon-save'),
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }
}
