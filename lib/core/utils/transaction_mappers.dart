import '../../shared/domain/currency.dart';
import '../../shared/domain/transaction_type.dart';
import '../database/daos/transaction_dao.dart';
import '../../features/transactions/domain/entity/transaction.dart';

class TransactionMappers {
  TransactionMappers._();

  static TransactionRow rowFromMap(Map<String, dynamic> map) {
    return TransactionRow(
      id: map['id'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      date: map['date'] as int,
      createdAt: map['created_at'] as int,
      categoryId: map['category_id'] as String?,
      savingsGoalId: map['savings_goal_id'] as String?,
      note: map['note'] as String?,
    );
  }

  static Transaction toEntity(TransactionRow row) {
    return Transaction(
      id: row.id,
      type: Transaction.typeFromDb(row.type),
      amount: row.amount,
      currency: Currency.fromCode(row.currency),
      date: row.date,
      createdAt: row.createdAt,
      categoryId: row.categoryId,
      savingsGoalId: row.savingsGoalId,
      note: row.note,
    );
  }
}
