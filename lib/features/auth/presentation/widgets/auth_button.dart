import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';

/// Botón de acceso con feedback de presión (scale 0.98) y estado de carga.
class AuthButton extends StatefulWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.leading,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.height = 52,
    this.centered = false,
    this.loading = false,
    this.boxShadow,
  });

  final String label;
  final Widget leading;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final double height;

  /// `true`: ícono y texto juntos al centro. `false`: ícono a la izquierda.
  final bool centered;
  final bool loading;
  final List<BoxShadow>? boxShadow;

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final labelStyle = AppTypography.button.copyWith(
      color: widget.foregroundColor,
    );
    final leading = SizedBox.square(
      dimension: 24,
      child: Center(
        child: widget.loading
            ? SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: widget.foregroundColor,
                ),
              )
            : widget.leading,
      ),
    );

    final content = widget.centered
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  style: labelStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        : Row(
            children: [
              leading,
              Expanded(
                child: Text(
                  widget.label,
                  style: labelStyle,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 24),
            ],
          );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 150),
        child: AnimatedOpacity(
          opacity: enabled || widget.loading ? 1 : 0.55,
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: widget.boxShadow,
            ),
            child: Material(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onPressed,
                onHighlightChanged: _setPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
