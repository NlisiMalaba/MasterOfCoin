import 'package:intl/intl.dart';

import '../../shared/domain/currency.dart';

/// Formats monetary amounts for display.
class CurrencyFormatter {
  const CurrencyFormatter._();

  static final _usdFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final _zwgFormat = NumberFormat.currency(
    symbol: 'Z\$',
    decimalDigits: 2,
  );

  static String format(double amount, Currency currency) {
    return switch (currency) {
      Currency.usd => _usdFormat.format(amount),
      Currency.zwg => _zwgFormat.format(amount),
    };
  }

  static String formatCompact(double amount, Currency currency) {
    if (amount >= 1000000) {
      return '${currency.symbol}${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${currency.symbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount, currency);
  }
}
