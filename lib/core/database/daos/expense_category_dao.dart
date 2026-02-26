import 'package:sqflite/sqflite.dart';

import '../app_database.dart';
import '../../../features/expenses/domain/entity/expense_category.dart';

class ExpenseCategoryDao {
  ExpenseCategoryDao(this._db);

  final AppDatabase _db;

  static const String _table = 'expense_categories';

  Future<void> insert(ExpenseCategory category) async {
    await _db.db.insert(
      _table,
      _toMap(category),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(ExpenseCategory category) async {
    await _db.db.update(
      _table,
      _toMap(category),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<ExpenseCategory?> getById(String id) async {
    final rows = await _db.db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  Future<List<ExpenseCategory>> getAll() async {
    final rows = await _db.db.query(
      _table,
      orderBy: 'name ASC',
    );
    return rows.map(_fromMap).toList();
  }

  Map<String, dynamic> _toMap(ExpenseCategory category) {
    return {
      'id': category.id,
      'name': category.name,
      'icon_name': category.iconName,
      'color_hex': category.colorHex,
      'is_system': category.isSystem ? 1 : 0,
      'created_at': category.createdAt,
    };
  }

  ExpenseCategory _fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] as int,
      iconName: map['icon_name'] as String?,
      colorHex: map['color_hex'] as int?,
      isSystem: (map['is_system'] as int?) == 1,
    );
  }
}
