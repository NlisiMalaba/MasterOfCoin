import 'package:sqflite/sqflite.dart';

import '../../../shared/domain/currency.dart';
import '../app_database.dart';
import '../daos/transaction_dao.dart';
import '../../../features/savings_goals/domain/entity/savings_goal.dart';

class SavingsGoalDao {
  SavingsGoalDao(this._db, this._transactionDao);

  final AppDatabase _db;
  final TransactionDao _transactionDao;

  static const String _table = 'savings_goals';

  Future<void> insert(SavingsGoal goal) async {
    await _db.db.insert(
      _table,
      _toMap(goal),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(SavingsGoal goal) async {
    await _db.db.update(
      _table,
      _toMap(goal),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<SavingsGoal?> getById(String id) async {
    final rows = await _db.db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final goal = _fromMap(rows.first);
    return _withCurrentAmount(goal);
  }

  Future<List<SavingsGoal>> getAll() async {
    final rows = await _db.db.query(
      _table,
      orderBy: 'CASE WHEN deadline_date IS NULL THEN 1 ELSE 0 END, deadline_date ASC, created_at DESC',
    );
    final goals = rows.map(_fromMap).toList();
    return Future.wait(goals.map(_withCurrentAmount));
  }

  Future<List<SavingsGoal>> getActiveWithDeadline() async {
    final now = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    final rows = await _db.db.query(
      _table,
      where: 'deadline_date IS NOT NULL AND deadline_date >= ?',
      whereArgs: [now],
      orderBy: 'deadline_date ASC',
      limit: 5,
    );
    final goals = rows.map(_fromMap).toList();
    return Future.wait(goals.map(_withCurrentAmount));
  }

  Future<SavingsGoal> _withCurrentAmount(SavingsGoal goal) async {
    final amount = await _transactionDao.sumSavingsByGoal(goal.id);
    return goal.copyWith(currentAmount: amount);
  }

  Map<String, dynamic> _toMap(SavingsGoal goal) {
    return {
      'id': goal.id,
      'name': goal.name,
      'target_amount': goal.targetAmount,
      'currency': goal.currency.code,
      'current_amount': goal.currentAmount,
      'deadline_date': goal.deadlineDate,
      'icon_name': goal.iconName,
      'created_at': goal.createdAt,
      'updated_at': goal.updatedAt,
    };
  }

  SavingsGoal _fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] as String,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currency: Currency.fromCode(map['currency'] as String),
      currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0,
      deadlineDate: map['deadline_date'] as int?,
      iconName: map['icon_name'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }
}
