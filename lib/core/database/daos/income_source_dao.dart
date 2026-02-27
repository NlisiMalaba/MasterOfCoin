import 'package:sqflite/sqflite.dart';

import '../../../shared/domain/currency.dart';
import '../app_database.dart';
import '../../../features/income/domain/entity/income_source.dart';

class IncomeSourceDao {
  IncomeSourceDao(this._db);

  final AppDatabase _db;

  static const String _table = 'income_sources';

  Future<void> insert(IncomeSource source) async {
    await _db.db.insert(
      _table,
      _toMap(source),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(IncomeSource source) async {
    await _db.db.update(
      _table,
      _toMap(source),
      where: 'id = ?',
      whereArgs: [source.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<IncomeSource?> getById(String id) async {
    final rows = await _db.db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  Future<List<IncomeSource>> getAll({bool activeOnly = true}) async {
    final where = activeOnly ? 'is_active = 1' : null;
    final rows = await _db.db.query(
      _table,
      where: where,
      orderBy: 'name ASC',
    );
    return rows.map(_fromMap).toList();
  }

  Future<List<IncomeSource>> getByCurrency(Currency currency) async {
    final rows = await _db.db.query(
      _table,
      where: 'currency = ? AND is_active = 1',
      whereArgs: [currency.code],
      orderBy: 'name ASC',
    );
    return rows.map(_fromMap).toList();
  }

  Map<String, dynamic> _toMap(IncomeSource source) {
    return {
      'id': source.id,
      'name': source.name,
      'currency': source.currency.code,
      'is_active': source.isActive ? 1 : 0,
      'created_at': source.createdAt,
    };
  }

  IncomeSource _fromMap(Map<String, dynamic> map) {
    return IncomeSource(
      id: map['id'] as String,
      name: map['name'] as String,
      currency: Currency.fromCode(map['currency'] as String),
      createdAt: map['created_at'] as int,
      isActive: (map['is_active'] as int) == 1,
    );
  }
}
