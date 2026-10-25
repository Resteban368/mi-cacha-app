import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../business_reservations/domain/entities/customer.dart';
import '../../domain/entities/client_profile.dart';
import '../../domain/entities/customer_failure.dart';
import '../../domain/entities/customer_payload.dart';
import '../../domain/usecases/create_business_customer.dart';
import '../../domain/usecases/update_business_customer.dart';

/// Modal dialog para crear o editar un cliente conectando con la API y manejando errores 409 (duplicados).
Future<ClientProfile?> showClientFormDialog(
  BuildContext context, {
  ClientProfile? initialClient,
  CreateBusinessCustomer? createUseCase,
  UpdateBusinessCustomer? updateUseCase,
}) {
  return showDialog<ClientProfile>(
    context: context,
    builder: (context) => _ClientFormDialog(
      initialClient: initialClient,
      createUseCase: createUseCase ?? (sl.isRegistered<CreateBusinessCustomer>() ? sl<CreateBusinessCustomer>() : null),
      updateUseCase: updateUseCase ?? (sl.isRegistered<UpdateBusinessCustomer>() ? sl<UpdateBusinessCustomer>() : null),
    ),
  );
}

class _ClientFormDialog extends StatefulWidget {
  const _ClientFormDialog({
    this.initialClient,
    this.createUseCase,
    this.updateUseCase,
  });

  final ClientProfile? initialClient;
  final CreateBusinessCustomer? createUseCase;
  final UpdateBusinessCustomer? updateUseCase;

  @override
  State<_ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<_ClientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _document;
  late final TextEditingController _email;
  late final TextEditingController _notes;
  late String _sport;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final c = widget.initialClient;
    _name = TextEditingController(text: c?.name ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _document = TextEditingController(text: c?.documentId ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _notes = TextEditingController(text: c?.notes ?? '');
    _sport = c?.preferredSport.isNotEmpty == true ? c!.preferredSport : 'Fútbol';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _document.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final payload = CustomerPayload(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      documentId: _document.text.trim(),
      preferredSport: _sport,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    try {
      ClientProfile result;
      if (widget.initialClient != null) {
        if (widget.updateUseCase != null) {
          result = await widget.updateUseCase!(
            UpdateCustomerParams(id: widget.initialClient!.id, payload: payload),
          );
        } else {
          result = widget.initialClient!.copyWith(
            name: payload.name,
            phone: payload.phone,
            documentId: payload.documentId,
            preferredSport: payload.preferredSport,
            notes: payload.notes ?? '',
          );
        }
      } else {
        if (widget.createUseCase != null) {
          result = await widget.createUseCase!(payload);
        } else {
          result = ClientProfile(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: payload.name,
            phone: payload.phone,
            documentId: payload.documentId,
            preferredSport: payload.preferredSport ?? 'Fútbol',
            notes: payload.notes ?? '',
            createdAt: DateTime.now(),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } on CustomerException catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.message ??
              (e.failure == CustomerFailure.conflict
                  ? 'Ya existe un cliente con este número de teléfono o documento.'
                  : 'Error al procesar la solicitud.');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialClient != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.brandTealLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isEdit ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded,
                              color: AppColors.brandTeal,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEdit ? 'Editar Cliente' : 'Nuevo Cliente',
                            style: AppTypography.headlineSm.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.dangerTint,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.statusDue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: AppColors.statusDue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.dangerInk,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  AppTextField(
                    controller: _name,
                    label: 'Nombre completo',
                    prefixIcon: Icons.badge_outlined,
                    hintText: 'Ej. Laura Gómez',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [LengthLimitingTextInputFormatter(100)],
                    validator: (v) => NewCustomer.validateName(v ?? ''),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _phone,
                          label: 'Teléfono / WhatsApp',
                          prefixIcon: Icons.phone_outlined,
                          hintText: 'Ej. 311 555 0001',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[\d\s()+-]'),
                            ),
                            LengthLimitingTextInputFormatter(20),
                          ],
                          validator: (v) => NewCustomer.validatePhone(v ?? ''),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          controller: _document,
                          label: 'Cédula / Documento',
                          prefixIcon: Icons.credit_card_outlined,
                          hintText: 'Ej. 1.075.111.222',
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(20),
                          ],
                          validator: (v) =>
                              NewCustomer.validateDocument(v ?? ''),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _sport,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'DEPORTE HABITUAL',
                      labelStyle: AppTypography.labelSm.copyWith(
                        color: AppColors.slate600,
                        fontWeight: FontWeight.w700,
                      ),
                      filled: true,
                      fillColor: AppColors.slate50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.slate200,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.slate200,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Fútbol',
                        child: Text('Fútbol'),
                      ),
                      DropdownMenuItem(
                        value: 'Pádel',
                        child: Text('Pádel'),
                      ),
                      DropdownMenuItem(
                        value: 'Baloncesto',
                        child: Text('Baloncesto'),
                      ),
                      DropdownMenuItem(
                        value: 'Voleibol',
                        child: Text('Voleibol'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _sport = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  AppTextField(
                    controller: _notes,
                    label: 'Notas internas / Preferencias',
                    prefixIcon: Icons.notes_rounded,
                    hintText:
                        'Ej. Juega martes por la noche, solicita petos...',
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandTeal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEdit ? 'Guardar Cambios' : 'Crear Cliente',
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
