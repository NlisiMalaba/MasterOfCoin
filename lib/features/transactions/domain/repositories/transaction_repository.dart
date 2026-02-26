import '../../../../shared/domain/currency.dart';
import '../../../../shared/domain/transaction_type.dart';
import '../entity/transaction.dart';

abstract class TransactionRepository {
  Future<void> addTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> deleteTransaction(String id);
  Future<Transaction?> getTransaction(String id);
  Future<List<Transaction>> getTransactions({
    TransactionType? type,
    Currency? currency,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    int? limit,
    int? offset,
  });
  Future<double> sumByTypeAndCurrency(
    TransactionType type,
    Currency currency, {
    DateTime? startDate,
    DateTime? endDate,
  });
}
