import 'package:intl/intl.dart';

final _pesosFmt = NumberFormat.currency(
  locale: 'es_AR',
  symbol: '\$',
  decimalDigits: 0,
);

final _numberFmt = NumberFormat('#,##0', 'es_AR');

String formatPesos(double value) => _pesosFmt.format(value);

String formatNumber(int value) => _numberFmt.format(value);
