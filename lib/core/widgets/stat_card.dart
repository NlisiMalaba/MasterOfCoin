import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A compact stat card for income/expense display with icon and colored accent.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.amount,
    required this.isPositive,
    this.color,
    this.icon,
  });

  final String label;
  final String amount;
  final bool isPositive;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final defaultColor = isPositive
        ? AppTheme.positiveColor(context)
        : AppTheme.negativeColor(context);
    final displayColor = color ?? defaultColor;
    final displayIcon = icon ?? (isPositive ? Icons.arrow_upward : Icons.arrow_downward);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.06,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            displayIcon,
            color: displayColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  amount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: displayColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
