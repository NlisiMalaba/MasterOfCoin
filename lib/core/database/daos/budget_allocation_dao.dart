import 'package:sqflite/sqflite.dart';

import '../../shared/domain/currency.dart';
import '../app_database.dart';
import '../../../features/budgets/domain/entity/budget_allocation.dart';

class BudgetAllocationDao {
  BudgetAllocationDao(this._db);

  final AppDatabase _db;

  static const String _table = 'budget_allocations';

  Future<void> insert(BudgetAllocation allocation) async {
    await _db.db.insert(
      _table,
      _toMap(allocation),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(BudgetAllocation allocation) async {
    await _db.db.update(
      _table,
      _toMap(allocation),
      where: 'id = ?',
      whereArgs: [allocation.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<BudgetAllocation?> getById(String id) async {
    final rows = await _db.db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  Future<List<BudgetAllocation>> getForPeriod(int periodStart, int periodEnd) async {
    final rows = await _db.db.query(
      _table,
      where: 'period_start = ? AND period_end = ?',
      whereArgs: [periodStart, periodEnd],
      orderBy: 'category_id ASC',
    );
    return rows.map(_fromMap).toList();
  }

  Future<BudgetAllocation?> getForCategoryAndPeriod(
    String categoryId,
    int periodStart,
    int periodEnd,
  ) async {
    final rows = await _db.db.query(
      _table,
      where: 'category_id = ? AND period_start = ? AND period_end = ?',
      whereArgs: [categoryId, periodStart, periodEnd],
    );
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  Map<String, dynamic> _toMap(BudgetAllocation allocation) {
    return {
      'id': allocation.id,
      'category_id': allocation.categoryId,
      'amount': allocation.amount,
      'currency': allocation.currency.code,
      'period_start': allocation.periodStart,
      'period_end': allocation.periodEnd,
      'created_at': allocation.createdAt,
    };
  }

  BudgetAllocation _fromMap(Map<String, dynamic> map) {
    return BudgetAllocation(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: Currency.fromCode(map['currency'] as String),
      periodStart: map['period_start'] as int,
      periodEnd: map['period_end'] as int,
      createdAt: map['created_at'] as int,
    );
  }
}
