import '../../../shared/domain/currency.dart';
import '../app_database.dart';
import '../../../features/savings_goals/domain/entity/savings_usage.dart';

class SavingsUsageDao {
  SavingsUsageDao(this._db);

  final AppDatabase _db;

  static const String _table = 'savings_usage';

  Future<void> insert(SavingsUsageRow row) async {
    await _db.db.insert(_table, _toMap(row));
  }

  Future<void> delete(String id) async {
    await _db.db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<double> sumByGoal(String savingsGoalId) async {
    final result = await _db.db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM $_table WHERE savings_goal_id = ?',
      [savingsGoalId],
    );
    final value = result.first['total'];
    return (value as num?)?.toDouble() ?? 0;
  }

  Future<List<SavingsUsage>> getAllWithGoalNames() async {
    final rows = await _db.db.rawQuery('''
      SELECT u.*, g.name as goal_name, g.currency as goal_currency
      FROM $_table u
      LEFT JOIN savings_goals g ON u.savings_goal_id = g.id
      ORDER BY u.date DESC, u.created_at DESC
    ''');
    return rows.map(_fromMap).toList();
  }

  Future<List<SavingsUsage>> getByGoal(String savingsGoalId) async {
    final rows = await _db.db.rawQuery('''
      SELECT u.*, g.name as goal_name, g.currency as goal_currency
      FROM $_table u
      LEFT JOIN savings_goals g ON u.savings_goal_id = g.id
      WHERE u.savings_goal_id = ?
      ORDER BY u.date DESC, u.created_at DESC
    ''', [savingsGoalId]);
    return rows.map(_fromMap).toList();
  }

  Map<String, dynamic> _toMap(SavingsUsageRow row) => {
        'id': row.id,
        'savings_goal_id': row.savingsGoalId,
        'amount': row.amount,
        'purpose': row.purpose,
        'date': row.date,
        'created_at': row.createdAt,
      };

  SavingsUsage _fromMap(Map<String, dynamic> map) => SavingsUsage(
        id: map['id'] as String,
        savingsGoalId: map['savings_goal_id'] as String,
        amount: (map['amount'] as num).toDouble(),
        purpose: map['purpose'] as String,
        date: map['date'] as int,
        createdAt: map['created_at'] as int,
        goalName: map['goal_name'] as String?,
        currency: map['goal_currency'] != null
            ? Currency.fromCode(map['goal_currency'] as String)
            : null,
      );
}

class SavingsUsageRow {
  SavingsUsageRow({
    required this.id,
    required this.savingsGoalId,
    required this.amount,
    required this.purpose,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String savingsGoalId;
  final double amount;
  final String purpose;
  final int date;
  final int createdAt;
}
