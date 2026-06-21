import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _pesosFmt = NumberFormat.currency(
  locale: 'es_AR',
  symbol: '\$',
  decimalDigits: 0,
);

final _numberFmt = NumberFormat('#,##0', 'es_AR');

String formatPesos(double value) => _pesosFmt.format(value);

String formatNumber(int value) => _numberFmt.format(value);

/// Formatea en tiempo real con puntos de miles al estilo peso chileno.
/// Ejemplo: al escribir "2000" muestra "2.000"
class ChileanPesoInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final n = int.tryParse(digits);
    if (n == null) return oldValue;
    final formatted = _numberFmt.format(n);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
