import 'package:equatable/equatable.dart';

import '../../../../shared/domain/currency.dart';

/// Monthly budget allocation (envelope) per expense category.
class BudgetAllocation extends Equatable {
  const BudgetAllocation({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.currency,
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
  });

  final String id;
  final String categoryId;
  final double amount;
  final Currency currency;
  final int periodStart;
  final int periodEnd;
  final int createdAt;

  @override
  List<Object?> get props => [id, categoryId, amount, currency, periodStart, periodEnd, createdAt];

  BudgetAllocation copyWith({
    String? id,
    String? categoryId,
    double? amount,
    Currency? currency,
    int? periodStart,
    int? periodEnd,
    int? createdAt,
  }) {
    return BudgetAllocation(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
