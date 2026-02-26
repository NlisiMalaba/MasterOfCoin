import '../../../../core/database/daos/transaction_dao.dart';
import '../../../../core/utils/transaction_mappers.dart';
import '../../../../shared/domain/currency.dart';
import '../../../../shared/domain/transaction_type.dart';
import '../../domain/entity/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._dao);

  final TransactionDao _dao;

  int _toUnix(DateTime? dt) {
    if (dt == null) return 0;
    return (dt.millisecondsSinceEpoch / 1000).round();
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    await _dao.insert(TransactionInsert(
      id: transaction.id,
      type: transaction.type,
      amount: transaction.amount,
      currency: transaction.currency,
      date: transaction.date,
      createdAt: transaction.createdAt,
      categoryId: transaction.categoryId,
      savingsGoalId: transaction.savingsGoalId,
      note: transaction.note,
    ));
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    await _dao.update(TransactionInsert(
      id: transaction.id,
      type: transaction.type,
      amount: transaction.amount,
      currency: transaction.currency,
      date: transaction.date,
      createdAt: transaction.createdAt,
      categoryId: transaction.categoryId,
      savingsGoalId: transaction.savingsGoalId,
      note: transaction.note,
    ));
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _dao.delete(id);
  }

  @override
  Future<Transaction?> getTransaction(String id) async {
    final row = await _dao.getById(id);
    return row != null ? TransactionMappers.toEntity(row) : null;
  }

  @override
  Future<List<Transaction>> getTransactions({
    TransactionType? type,
    Currency? currency,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    int? limit,
    int? offset,
  }) async {
    final rows = await _dao.getAll(
      type: type,
      currency: currency?.code,
      startDate: startDate != null ? _toUnix(startDate) : null,
      endDate: endDate != null ? _toUnix(endDate) : null,
      categoryId: categoryId,
      limit: limit,
      offset: offset,
    );
    return rows.map(TransactionMappers.toEntity).toList();
  }

  @override
  Future<double> sumByTypeAndCurrency(
    TransactionType type,
    Currency currency, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _dao.sumByTypeAndCurrency(
      type,
      currency.code,
      startDate: startDate != null ? _toUnix(startDate) : null,
      endDate: endDate != null ? _toUnix(endDate) : null,
    );
  }
}
