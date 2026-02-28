import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';
import 'backup_restore_result.dart';

/// Service for backing up and restoring the SQLite database.
///
/// Backup creates a copy of the database file and opens the system share sheet,
/// allowing the user to save to Google Drive, email, or local storage.
///
/// Restore lets the user pick a backup file (e.g. from Google Drive) and
/// replaces the current database. The app will use the restored data.
class BackupRestoreService {
  BackupRestoreService({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  static const String _backupExtension = 'mocbackup';
  static const int _sqliteHeader = 0x53514C69; // "Sqli" - SQLite magic

  /// Creates a backup of the database and opens the share sheet.
  ///
  /// The user can save the file to Google Drive, email, or local storage.
  /// Returns [BackupSuccess] when shared, [BackupRestoreCancelled] if user
  /// dismisses the share sheet, or [BackupRestoreFailure] on error.
  Future<BackupRestoreResult> backup() async {
    final dbPath = _database.dbPath;
    if (dbPath == null) {
      return const BackupRestoreFailure(
        message: 'Database not initialized',
      );
    }

    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      return const BackupRestoreFailure(
        message: 'Database file not found',
      );
    }

    try {
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupName = 'master_of_coin_backup_$timestamp.$_backupExtension';
      final backupFile = File(p.join(tempDir.path, backupName));

      await dbFile.copy(backupFile.path);

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'MasterOfCoin Backup',
        text: 'MasterOfCoin data backup. Restore from Settings in the app.',
      );

      await backupFile.delete();

      return BackupSuccess(path: backupName);
    } on IOException catch (e) {
      return BackupRestoreFailure(message: 'Failed to create backup: $e');
    } catch (e) {
      return BackupRestoreFailure(message: 'Backup failed: $e');
    }
  }

  /// Restores the database from a user-selected backup file.
  ///
  /// Opens the file picker; user can select a backup from device or Google Drive.
  /// Replaces the current database and reopens it.
  /// Returns [RestoreSuccess], [BackupRestoreCancelled], or [BackupRestoreFailure].
  Future<BackupRestoreResult> restore() async {
    final dbPath = _database.dbPath;
    if (dbPath == null) {
      return const BackupRestoreFailure(
        message: 'Database not initialized',
      );
    }

    try {
      await FilePicker.platform.clearTemporaryFiles();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', _backupExtension],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return const BackupRestoreCancelled();
      }

      final selectedPath = result.files.single.path;
      if (selectedPath == null || selectedPath.isEmpty) {
        return const BackupRestoreFailure(
          message: 'Could not access selected file',
        );
      }

      final backupFile = File(selectedPath);
      if (!await backupFile.exists()) {
        return const BackupRestoreFailure(
          message: 'Selected file does not exist',
        );
      }

      if (!await _isValidSqliteFile(backupFile)) {
        return const BackupRestoreFailure(
          message: 'Selected file is not a valid MasterOfCoin backup',
        );
      }

      final currentDb = File(dbPath);
      final rollbackPath = '$dbPath.before_restore';
      if (await currentDb.exists()) {
        await currentDb.copy(rollbackPath);
      }

      try {
        await _database.close();
        await backupFile.copy(dbPath);
        await _database.reopen();
        final rollbackFile = File(rollbackPath);
        if (await rollbackFile.exists()) await rollbackFile.delete();
        return const RestoreSuccess();
      } catch (e) {
        final rollbackFile = File(rollbackPath);
        if (await rollbackFile.exists()) {
          await rollbackFile.copy(dbPath);
        }
        await _database.reopen();
        return BackupRestoreFailure(message: 'Restore failed: $e');
      }
    } on IOException catch (e) {
      return BackupRestoreFailure(message: 'Failed to restore: $e');
    } catch (e) {
      return BackupRestoreFailure(message: 'Restore failed: $e');
    }
  }

  /// Validates that the file is a SQLite database by checking the header.
  Future<bool> _isValidSqliteFile(File file) async {
    try {
      final bytes = await file.openRead(0, 16).first;
      if (bytes.length < 16) return false;
      final magic = bytes[0] |
          (bytes[1] << 8) |
          (bytes[2] << 16) |
          (bytes[3] << 24);
      return magic == _sqliteHeader;
    } catch (_) {
      return false;
    }
  }
}
