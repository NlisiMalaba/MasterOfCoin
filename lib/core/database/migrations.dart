import 'package:sqflite/sqflite.dart';

/// Database migrations for schema versioning.
class Migrations {
  Migrations._();

  static Future<void> runMigrations(Database db, int version) async {
    if (version >= 1) {
      await _createV1Schema(db);
    }
  }

  static Future<void> _createV1Schema(Database db) async {
    await db.execute('''
      CREATE TABLE income_sources (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        currency TEXT NOT NULL CHECK(currency IN ('USD','ZWG')),
        is_active INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_name TEXT,
        color_hex INTEGER,
        is_system INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        currency TEXT NOT NULL,
        current_amount REAL DEFAULT 0,
        deadline_date INTEGER,
        icon_name TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL CHECK(type IN ('income','expense','transfer')),
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        category_id TEXT,
        savings_goal_id TEXT,
        note TEXT,
        date INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budget_allocations (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        period_start INTEGER NOT NULL,
        period_end INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE exchange_rates (
        id TEXT PRIMARY KEY,
        rate REAL NOT NULL,
        date INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_transactions_type ON transactions(type)');
    await db.execute('CREATE INDEX idx_transactions_currency ON transactions(currency)');
    await db.execute('CREATE INDEX idx_budget_allocations_period ON budget_allocations(period_start, period_end)');

    await db.execute('''
      CREATE TABLE recurring_templates (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL CHECK(type IN ('income','expense')),
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        category_id TEXT,
        note TEXT,
        recurrence TEXT NOT NULL CHECK(recurrence IN ('weekly','monthly')),
        last_applied_date INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
  }
}
