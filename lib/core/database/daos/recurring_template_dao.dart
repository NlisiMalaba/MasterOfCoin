import 'package:sqflite/sqflite.dart';

import '../../shared/domain/currency.dart';
import '../app_database.dart';

class RecurringTemplateDao {
  RecurringTemplateDao(this._db);

  final AppDatabase _db;

  static const String _table = 'recurring_templates';

  Future<void> insert(RecurringTemplateRow row) async {
    await _db.db.insert(
      _table,
      _toMap(row),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(RecurringTemplateRow row) async {
    await _db.db.update(
      _table,
      _toMap(row),
      where: 'id = ?',
      whereArgs: [row.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<RecurringTemplateRow?> getById(String id) async {
    final rows = await _db.db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  Future<List<RecurringTemplateRow>> getAll() async {
    final rows = await _db.db.query(_table, orderBy: 'created_at DESC');
    return rows.map(_fromMap).toList();
  }

  Map<String, dynamic> _toMap(RecurringTemplateRow row) {
    return {
      'id': row.id,
      'type': row.type,
      'amount': row.amount,
      'currency': row.currency.code,
      'category_id': row.categoryId,
      'note': row.note,
      'recurrence': row.recurrence,
      'last_applied_date': row.lastAppliedDate,
      'created_at': row.createdAt,
    };
  }

  RecurringTemplateRow _fromMap(Map<String, dynamic> map) {
    return RecurringTemplateRow(
      id: map['id'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: Currency.fromCode(map['currency'] as String),
      categoryId: map['category_id'] as String?,
      note: map['note'] as String?,
      recurrence: map['recurrence'] as String,
      lastAppliedDate: map['last_applied_date'] as int?,
      createdAt: map['created_at'] as int,
    );
  }
}

class RecurringTemplateRow {
  RecurringTemplateRow({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    this.categoryId,
    this.note,
    required this.recurrence,
    this.lastAppliedDate,
    required this.createdAt,
  });

  final String id;
  final String type;
  final double amount;
  final Currency currency;
  final String? categoryId;
  final String? note;
  final String recurrence;
  final int? lastAppliedDate;
  final int createdAt;
}
