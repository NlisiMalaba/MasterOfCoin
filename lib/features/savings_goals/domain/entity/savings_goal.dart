import 'package:equatable/equatable.dart';

import '../../../../shared/domain/currency.dart';

/// Savings goal with target amount and deadline.
class SavingsGoal extends Equatable {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    this.currentAmount = 0,
    this.deadlineDate,
    this.iconName,
  });

  final String id;
  final String name;
  final double targetAmount;
  final Currency currency;
  final double currentAmount;
  final int? deadlineDate;
  final String? iconName;
  final int createdAt;
  final int updatedAt;

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remaining => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  @override
  List<Object?> get props =>
      [id, name, targetAmount, currency, currentAmount, deadlineDate, iconName, createdAt, updatedAt];

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    Currency? currency,
    double? currentAmount,
    int? deadlineDate,
    String? iconName,
    int? createdAt,
    int? updatedAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currency: currency ?? this.currency,
      currentAmount: currentAmount ?? this.currentAmount,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
