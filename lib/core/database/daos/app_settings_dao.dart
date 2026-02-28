import 'package:sqflite/sqflite.dart';

import '../app_database.dart';

class AppSettingsDao {
  AppSettingsDao(this._db);

  final AppDatabase _db;

  static const String _table = 'app_settings';

  static const String keyDefaultCurrency = 'default_currency';
  static const String keyExchangeRate = 'exchange_rate';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyThemeMode = 'theme_mode';

  Future<String?> getString(String key) async {
    final rows = await _db.db.query(
      _table,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<double?> getDouble(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    return double.tryParse(value);
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await getString(key);
    if (value == null) return defaultValue;
    return value == '1' || value.toLowerCase() == 'true';
  }

  Future<void> setString(String key, String value) async {
    await _db.db.insert(
      _table,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setDouble(String key, double value) async {
    await setString(key, value.toString());
  }

  Future<void> setBool(String key, bool value) async {
    await setString(key, value ? '1' : '0');
  }
}
