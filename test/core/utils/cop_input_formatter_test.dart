import 'package:flutter_test/flutter_test.dart';
import 'package:mi_cancha/core/utils/cop_input_formatter.dart';

void main() {
  const formatter = CopInputFormatter();

  String type(String text) => formatter
      .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text))
      .text;

  test('agrega puntos de miles y descarta no dígitos', () {
    expect(type('50000'), '50.000');
    expect(type('1250000'), '1.250.000');
    expect(type(r'$12a3'), '123');
  });

  test('quita ceros a la izquierda y deja vacío si es 0', () {
    expect(type('000450'), '450');
    expect(type('0'), '');
  });

  test('parse y format son inversos', () {
    expect(CopInputFormatter.parse('1.250.000'), 1250000);
    expect(CopInputFormatter.parse(''), 0);
    expect(CopInputFormatter.format(50000), '50.000');
    expect(CopInputFormatter.format(0), '');
  });
}
