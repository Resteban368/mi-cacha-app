import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Campo de formulario con etiqueta superior en mayúsculas, ícono a la
/// izquierda y, si es contraseña, botón para mostrar/ocultar.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.prefixIcon,
    this.controller,
    this.hintText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onFieldSubmitted,
    this.isPassword = false,
    this.enabled = true,
    this.inputFormatters,
    this.onChanged,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
  });

  final String label;
  final IconData prefixIcon;
  final TextEditingController? controller;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final bool isPassword;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.isPassword;

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.spaceGrotesk(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.slate900,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: AppColors.slate700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          onFieldSubmitted: widget.onFieldSubmitted,
          onChanged: widget.onChanged,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          textCapitalization: widget.textCapitalization,
          validator: widget.validator,
          autocorrect: !widget.isPassword,
          enableSuggestions: !widget.isPassword,
          style: textStyle,
          cursorColor: AppColors.brandTeal,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: textStyle.copyWith(color: AppColors.slate400),
            filled: true,
            // Se aclara a blanco al enfocar, como en el diseño.
            fillColor: WidgetStateColor.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? Colors.white
                  : AppColors.slate50,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            prefixIcon: Icon(
              widget.prefixIcon,
              size: 20,
              color: AppColors.slate400,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    tooltip: _obscured
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.slate400,
                    ),
                  )
                : widget.suffixIcon,
            border: _border(AppColors.slate200),
            enabledBorder: _border(AppColors.slate200),
            disabledBorder: _border(AppColors.slate200),
            focusedBorder: _border(AppColors.brandTeal, 2),
            errorBorder: _border(AppColors.error),
            focusedErrorBorder: _border(AppColors.error, 2),
            errorStyle: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}
