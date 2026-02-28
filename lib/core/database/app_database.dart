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
  String? _dbPath;

  /// Full path to the database file. Available after [init] completes.
  String? get dbPath => _dbPath;

  Future<void> init(String documentsPath) async {
    _dbPath ??= join(documentsPath, _dbName);
    if (_db != null) return;
    _db = await openDatabase(
      _dbPath!,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    if (!_initCompleter.isCompleted) _initCompleter.complete();
  }

  /// Reopens the database after restore. Call after replacing the DB file.
  Future<void> reopen() async {
    await close();
    if (_dbPath == null) {
      throw StateError('Cannot reopen: database was never initialized.');
    }
    _db = await openDatabase(
      _dbPath!,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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
