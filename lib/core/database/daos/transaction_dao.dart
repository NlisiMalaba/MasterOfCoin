import 'package:sqflite/sqflite.dart';

import '../../shared/domain/currency.dart';
import '../../shared/domain/transaction_type.dart';
import '../app_database.dart';
import '../../utils/transaction_mappers.dart';

class TransactionDao {
  TransactionDao(this._db);

  final AppDatabase _db;

  static const String _table = 'transactions';

  Future<void> insert(TransactionInsert insert) async {
    await _db.db.insert(
      _table,
      _toMap(insert),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(TransactionInsert insert) async {
    await _db.db.update(
      _table,
      _toMap(insert),
      where: 'id = ?',
      whereArgs: [insert.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<TransactionRow?> getById(String id) async {
    final rows = await _db.db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return TransactionMappers.rowFromMap(rows.first);
  }

  Future<List<TransactionRow>> getAll({
    TransactionType? type,
    String? currency,
    int? startDate,
    int? endDate,
    String? categoryId,
    int? limit,
    int? offset,
  }) async {
    var where = <String>[];
    var whereArgs = <dynamic>[];

    if (type != null) {
      where.add('type = ?');
      whereArgs.add(type.name);
    }
    if (currency != null) {
      where.add('currency = ?');
      whereArgs.add(currency);
    }
    if (startDate != null) {
      where.add('date >= ?');
      whereArgs.add(startDate);
    }
    if (endDate != null) {
      where.add('date <= ?');
      whereArgs.add(endDate);
    }
    if (categoryId != null) {
      where.add('category_id = ?');
      whereArgs.add(categoryId);
    }

    final whereClause = where.isNotEmpty ? where.join(' AND ') : null;

    var query = _db.db.query(
      _table,
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );

    final rows = await query;
    return rows.map(TransactionMappers.rowFromMap).toList();
  }

  Future<double> sumByTypeAndCurrency(
    TransactionType type,
    String currency, {
    int? startDate,
    int? endDate,
  }) async {
    var where = 'type = ? AND currency = ?';
    var args = <dynamic>[type.name, currency];

    if (startDate != null) {
      where += ' AND date >= ?';
      args.add(startDate);
    }
    if (endDate != null) {
      where += ' AND date <= ?';
      args.add(endDate);
    }

    final result = await _db.db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM $_table WHERE $where',
      args,
    );
    final value = result.first['total'];
    return (value as num?)?.toDouble() ?? 0;
  }

  Future<double> sumExpensesByCategory(
    String categoryId,
    String currency, {
    int? startDate,
    int? endDate,
  }) async {
    var where = 'type = ? AND category_id = ? AND currency = ?';
    var args = <dynamic>['expense', categoryId, currency];

    if (startDate != null) {
      where += ' AND date >= ?';
      args.add(startDate);
    }
    if (endDate != null) {
      where += ' AND date <= ?';
      args.add(endDate);
    }

    final result = await _db.db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM $_table WHERE $where',
      args,
    );
    final value = result.first['total'];
    return (value as num?)?.toDouble() ?? 0;
  }

  Future<double> sumSavingsByGoal(String savingsGoalId) async {
    final result = await _db.db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM $_table '
      'WHERE type = ? AND savings_goal_id = ?',
      ['income', savingsGoalId],
    );
    final value = result.first['total'];
    return (value as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, dynamic>>> expensesByCategory({
    required String currency,
    int? startDate,
    int? endDate,
  }) async {
    var where = 'type = ? AND currency = ?';
    var args = <dynamic>['expense', currency];

    if (startDate != null) {
      where += ' AND date >= ?';
      args.add(startDate);
    }
    if (endDate != null) {
      where += ' AND date <= ?';
      args.add(endDate);
    }

    return _db.db.rawQuery(
      'SELECT category_id, SUM(amount) as total FROM $_table '
      'WHERE $where GROUP BY category_id ORDER BY total DESC',
      args,
    );
  }

  Future<List<Map<String, dynamic>>> monthlyTotals({
    required TransactionType type,
    required String currency,
    int months = 6,
  }) async {
    final endDate = DateTime.now();
    final startDate = DateTime(endDate.year, endDate.month - months, 1);
    final startSeconds = (startDate.millisecondsSinceEpoch / 1000).round();
    final endSeconds = (endDate.millisecondsSinceEpoch / 1000).round();

    return _db.db.rawQuery(
      'SELECT strftime("%Y-%m", datetime(date, "unixepoch")) as month, '
      'SUM(amount) as total FROM $_table '
      'WHERE type = ? AND currency = ? AND date >= ? AND date <= ? '
      'GROUP BY month ORDER BY month ASC',
      [type.name, currency, startSeconds, endSeconds],
    );
  }

  Map<String, dynamic> _toMap(TransactionInsert insert) {
    return {
      'id': insert.id,
      'type': insert.type.name,
      'amount': insert.amount,
      'currency': insert.currency.code,
      'category_id': insert.categoryId,
      'savings_goal_id': insert.savingsGoalId,
      'note': insert.note,
      'date': insert.date,
      'created_at': insert.createdAt,
    };
  }
}

class TransactionInsert {
  TransactionInsert({
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
}

class TransactionRow {
  TransactionRow({
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
  final String type;
  final double amount;
  final String currency;
  final int date;
  final int createdAt;
  final String? categoryId;
  final String? savingsGoalId;
  final String? note;
}
