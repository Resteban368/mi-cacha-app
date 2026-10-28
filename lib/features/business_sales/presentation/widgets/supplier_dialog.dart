import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/cash_session.dart';
import '../../domain/repositories/cash_repository.dart';

/// Formulario de proveedor (nuevo o editado). [onSave] devuelve el error para
/// mostrar o `null` si se guardó; el diálogo devuelve `true` al guardar.
Future<bool> showSupplierDialog(
  BuildContext context, {
  required Future<String?> Function(SupplierDraft draft) onSave,
  Supplier? supplier,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _SupplierDialog(supplier: supplier, onSave: onSave),
    ) ??
    false;

class _SupplierDialog extends StatefulWidget {
  const _SupplierDialog({required this.onSave, this.supplier});

  final Supplier? supplier;
  final Future<String?> Function(SupplierDraft draft) onSave;

  @override
  State<_SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends State<_SupplierDialog> {
  late final _name = TextEditingController(text: widget.supplier?.name);
  late final _document = TextEditingController(
    text: widget.supplier?.documentId,
  );
  late final _phone = TextEditingController(text: widget.supplier?.phone);
  late final _notes = TextEditingController(text: widget.supplier?.notes);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _document.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave((
      id: widget.supplier?.id,
      name: _name.text,
      documentId: _document.text,
      phone: _phone.text,
      notes: _notes.text,
    ));
    if (!mounted) return;
    if (error == null) {
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      scrollable: true,
      title: Text(
        widget.supplier == null ? 'Nuevo proveedor' : 'Editar proveedor',
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('supplier-name'),
              controller: _name,
              autofocus: widget.supplier == null,
              maxLength: Supplier.maxName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej. Distribuidora Postobón',
              ),
            ),
            TextField(
              key: const Key('supplier-document'),
              controller: _document,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: 'NIT o cédula (opcional)',
              ),
            ),
            TextField(
              key: const Key('supplier-phone'),
              controller: _phone,
              maxLength: 30,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
              ),
            ),
            TextField(
              key: const Key('supplier-notes'),
              controller: _notes,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Ej. Entrega los martes',
              ),
            ),
            if (_error case final error?)
              Text(
                error,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.statusDue,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('supplier-save'),
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }
}
