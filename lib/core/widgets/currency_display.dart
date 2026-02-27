import 'package:flutter/material.dart';

import '../utils/currency_formatter.dart';
import '../../shared/domain/currency.dart';

class CurrencyDisplay extends StatelessWidget {
  const CurrencyDisplay({
    super.key,
    required this.amount,
    required this.currency,
    this.compact = false,
  });

  final double amount;
  final String currency;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = Currency.fromCode(currency);
    final text = compact
        ? CurrencyFormatter.formatCompact(amount, c)
        : CurrencyFormatter.format(amount, c);
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
    );
  }
}
