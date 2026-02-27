import 'package:equatable/equatable.dart';

import '../../../../shared/domain/currency.dart';

/// Record of money withdrawn from a savings goal and where it was used.
class SavingsUsage extends Equatable {
  const SavingsUsage({
    required this.id,
    required this.savingsGoalId,
    required this.amount,
    required this.purpose,
    required this.date,
    required this.createdAt,
    this.currency,
    this.goalName,
  });

  final String id;
  final String savingsGoalId;
  final double amount;
  final String purpose;
  final int date;
  final int createdAt;
  final Currency? currency;
  final String? goalName;

  @override
  List<Object?> get props => [id, savingsGoalId, amount, purpose, date, createdAt];
}
