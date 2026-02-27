import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';

const String _dbName = 'master_of_coin.db';
const int _dbVersion = 2;

/// SQLite database for MasterOfCoin.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase _instance = AppDatabase._();
  static AppDatabase get instance => _instance;

  Database? _db;
  final _initCompleter = Completer<void>();

  Future<void> init(String path) async {
    if (_db != null) return;
    _db = await openDatabase(
      join(path, _dbName),
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _initCompleter.complete();
  }

  Future<void> get initialized async => _initCompleter.future;

  Database get db {
    final database = _db;
    if (database == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return database;
  }

  Future<void> close() async {
    final database = _db;
    if (database != null) {
      await database.close();
      _db = null;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await Migrations.runMigrations(db, version);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      await Migrations.runMigration(db, v);
    }
  }
}
