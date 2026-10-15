import 'package:flutter/services.dart';

import 'formatters.dart';

/// Formatea montos en COP mientras se escriben: `50000` → `50.000`.
/// Solo acepta dígitos (sin decimales).
class CopInputFormatter extends TextInputFormatter {
  const CopInputFormatter({this.maxDigits = 9});

  final int maxDigits;

  /// `"50.000"` → `50000` (0 si está vacío).
  static int parse(String text) =>
      int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  /// `50000` → `"50.000"`.
  static String format(int value) =>
      value <= 0 ? '' : AppFormatters.cop(value).substring(1);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > maxDigits) return oldValue;
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    final text = digits.isEmpty ? '' : format(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
