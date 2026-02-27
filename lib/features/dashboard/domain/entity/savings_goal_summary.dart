import 'package:equatable/equatable.dart';

import '../../../../shared/domain/currency.dart';

/// Lightweight savings goal summary for dashboard.
class SavingsGoalSummary extends Equatable {
  const SavingsGoalSummary({
    required this.id,
    required this.name,
    required this.currentAmount,
    required this.targetAmount,
    required this.currency,
  });

  final String id;
  final String name;
  final double currentAmount;
  final double targetAmount;
  final Currency currency;

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object?> get props => [id, name, currentAmount, targetAmount, currency];
}
