import 'package:flutter_test/flutter_test.dart';

import 'package:master_of_coin/core/utils/currency_formatter.dart';
import 'package:master_of_coin/shared/domain/currency.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats USD amounts', () {
      expect(CurrencyFormatter.format(100.5, Currency.usd), contains('\$'));
      expect(CurrencyFormatter.format(100.5, Currency.usd), contains('100'));
    });

    test('formats ZWG amounts', () {
      expect(CurrencyFormatter.format(1000, Currency.zwg), contains('Z\$'));
    });

    test('formatCompact abbreviates large numbers', () {
      expect(CurrencyFormatter.formatCompact(1500, Currency.usd), contains('1.5'));
      expect(CurrencyFormatter.formatCompact(1500000, Currency.usd), contains('1.5'));
    });
  });
}
