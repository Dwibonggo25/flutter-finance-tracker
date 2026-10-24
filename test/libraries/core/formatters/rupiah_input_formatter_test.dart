import 'package:finance_project/libraries/core/formatters/rupiah_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats digits using Indonesian thousands separators', () {
    const formatter = RupiahInputFormatter();
    final result = formatter.formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(text: '1000000'),
    );

    expect(result.text, '1.000.000');
    expect(result.selection.baseOffset, result.text.length);
  });

  test('parses a formatted Rupiah value', () {
    expect(parseRupiah('1.250.000'), 1250000);
  });
}
