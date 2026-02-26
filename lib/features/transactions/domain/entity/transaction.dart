import 'package:equatable/equatable.dart';

import '../../../../shared/domain/currency.dart';
import '../../../../shared/domain/transaction_type.dart';

/// A financial transaction (income, expense, or transfer).
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.date,
    required this.createdAt,
    this.categoryId,
    this.savingsGoalId,
    this.note,
  });

  final String id;
  final TransactionType type;
  final double amount;
  final Currency currency;
  final int date;
  final int createdAt;
  final String? categoryId;
  final String? savingsGoalId;
  final String? note;

  @override
  List<Object?> get props => [id, type, amount, currency, date, createdAt, categoryId, savingsGoalId, note];

  Transaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    Currency? currency,
    int? date,
    int? createdAt,
    String? categoryId,
    String? savingsGoalId,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      categoryId: categoryId ?? this.categoryId,
      savingsGoalId: savingsGoalId ?? this.savingsGoalId,
      note: note ?? this.note,
    );
  }

  static String typeToDb(TransactionType type) {
    return type.name;
  }

  static TransactionType typeFromDb(String value) {
    return TransactionType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => TransactionType.expense,
    );
  }
}
