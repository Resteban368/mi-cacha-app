import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/password_change.dart';
import '../bloc/change_password_cubit.dart';

/// Abre el formulario de cambio de contraseña. Al guardar avisa con un
/// snackbar y se cierra.
Future<void> showChangePasswordDialog(
  BuildContext context, {
  required ChangePasswordCubit Function() createCubit,
}) async {
  final changed = await showDialog<bool>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => createCubit(),
      child: const ChangePasswordDialog(),
    ),
  );
  if (changed != true || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  var _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validateCurrent(String? value) =>
      (value ?? '').isEmpty ? 'Ingresa tu contraseña actual' : null;

  String? _validateNew(String? value) {
    final password = value ?? '';
    if (password.length < PasswordChange.minLength) {
      return 'Debe tener al menos ${PasswordChange.minLength} caracteres';
    }
    if (password.length > PasswordChange.maxLength) {
      return 'Debe tener máximo ${PasswordChange.maxLength} caracteres';
    }
    if (password == _current.text) {
      return 'Debe ser distinta a la actual';
    }
    return null;
  }

  String? _validateConfirm(String? value) =>
      value != _new.text ? 'Las contraseñas no coinciden' : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<ChangePasswordCubit>().submit(
      PasswordChange(currentPassword: _current.text, newPassword: _new.text),
    );
  }

  static String _errorText(ChangePasswordState state) =>
      switch (state.failure) {
        PasswordChangeFailure.network =>
          'Sin conexión. Revisa tu internet e intenta de nuevo.',
        PasswordChangeFailure.rejected when state.message != null =>
          state.message!,
        _ => 'No pudimos cambiar la contraseña. Intenta de nuevo.',
      };

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == ChangePasswordStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final busy = state.isSubmitting;
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidate,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Cambiar contraseña',
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Usa entre ${PasswordChange.minLength} y '
                      '${PasswordChange.maxLength} caracteres.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      key: const Key('password-current'),
                      label: 'Contraseña actual',
                      prefixIcon: Icons.lock_outline,
                      controller: _current,
                      isPassword: true,
                      enabled: !busy,
                      validator: _validateCurrent,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      key: const Key('password-new'),
                      label: 'Nueva contraseña',
                      prefixIcon: Icons.lock_reset,
                      controller: _new,
                      isPassword: true,
                      enabled: !busy,
                      validator: _validateNew,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      key: const Key('password-confirm'),
                      label: 'Confirmar nueva contraseña',
                      prefixIcon: Icons.lock_reset,
                      controller: _confirm,
                      isPassword: true,
                      enabled: !busy,
                      validator: _validateConfirm,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => busy ? null : _submit(),
                    ),
                    if (state.status == ChangePasswordStatus.failure) ...[
                      const SizedBox(height: 12),
                      Container(
                        key: const Key('password-error'),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorText(state),
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          key: const Key('password-cancel'),
                          onPressed: busy
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          key: const Key('password-submit'),
                          onPressed: busy ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandTeal,
                            foregroundColor: AppColors.onPrimary,
                          ),
                          child: busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : const Text('Guardar contraseña'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
