import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';
import '../database/daos/app_settings_dao.dart';
import 'backup_env.dart';
import 'backup_restore_result.dart';

/// Service for backing up and restoring the SQLite database.
///
/// Backup creates a copy of the database file and opens the system share sheet,
/// allowing the user to save to Google Drive, email, or local storage.
/// Optional AES encryption is available when [AppSettingsDao.keyEncryptBackups] is enabled.
///
/// Restore lets the user pick a backup file (e.g. from Google Drive) and
/// replaces the current database. Supports both encrypted (.mocbackup) and raw (.db) backups.
class BackupRestoreService {
  BackupRestoreService({
    required AppDatabase database,
    required AppSettingsDao settingsDao,
  })  : _database = database,
        _settingsDao = settingsDao;

  final AppDatabase _database;
  final AppSettingsDao _settingsDao;

  static const String _backupExtension = 'mocbackup';
  static const int _sqliteHeader = 0x53514C69; // "Sqli" - SQLite magic
  static const int _encryptedMagic = 0x4D4F4345; // "MOCE"

  /// Creates a backup of the database and opens the share sheet.
  ///
  /// When [AppSettingsDao.keyEncryptBackups] is true, the backup is AES-encrypted.
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
      final encryptEnabled = await _settingsDao.getBool(
        AppSettingsDao.keyEncryptBackups,
        defaultValue: false,
      );

      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupName = 'master_of_coin_backup_$timestamp.$_backupExtension';
      final backupFile = File(p.join(tempDir.path, backupName));

      if (encryptEnabled) {
        final data = await dbFile.readAsBytes();
        final encrypted = _encryptBytes(data);
        await backupFile.writeAsBytes(encrypted);
      } else {
        await dbFile.copy(backupFile.path);
      }

      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'MasterOfCoin Backup',
        text: encryptEnabled
            ? 'MasterOfCoin encrypted backup. Restore from app start or Settings.'
            : 'MasterOfCoin data backup. Restore from app start or Settings.',
      );

      await backupFile.delete();

      return BackupSuccess(path: backupName);
    } on IOException catch (e) {
      return BackupRestoreFailure(message: 'Failed to create backup: $e');
    } catch (e) {
      return BackupRestoreFailure(message: 'Backup failed: $e');
    }
  }

  /// Creates a backup file without sharing. Used for scheduled backups.
  ///
  /// Returns the path to the backup file, or null on failure.
  Future<String?> createBackupFile() async {
    final dbPath = _database.dbPath;
    if (dbPath == null) return null;

    final dbFile = File(dbPath);
    if (!await dbFile.exists()) return null;

    try {
      final encryptEnabled = await _settingsDao.getBool(
        AppSettingsDao.keyEncryptBackups,
        defaultValue: false,
      );

      final dir = Directory(p.join(p.dirname(dbPath), 'backups'));
      if (!await dir.exists()) await dir.create(recursive: true);

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = p.join(dir.path, 'backup_$timestamp.$_backupExtension');

      if (encryptEnabled) {
        final data = await dbFile.readAsBytes();
        final encrypted = _encryptBytes(data);
        await File(backupPath).writeAsBytes(encrypted);
      } else {
        await dbFile.copy(backupPath);
      }

      return backupPath;
    } catch (_) {
      return null;
    }
  }

  /// Restores the database from a user-selected backup file.
  ///
  /// Supports both encrypted (MOCE header) and raw SQLite backups.
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

      final bytes = await backupFile.readAsBytes();
      final dataToRestore = await _bytesToRestore(bytes);
      if (dataToRestore == null) {
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
        await File(dbPath).writeAsBytes(dataToRestore);
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

  /// Converts backup bytes to SQLite bytes. Returns null if invalid.
  Future<List<int>?> _bytesToRestore(List<int> bytes) async {
    if (bytes.length < 16) return null;

    final magic = bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);

    if (magic == _encryptedMagic) {
      try {
        return _decryptBytes(bytes.sublist(4));
      } catch (_) {
        return null;
      }
    }

    if (magic == _sqliteHeader) {
      return bytes;
    }

    return null;
  }

  List<int> _encryptBytes(List<int> data) {
    final key = Key.fromUtf8(BackupEnv.encryptKey);
    final iv = IV.fromUtf8(BackupEnv.encryptIv);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    final magic = [
      _encryptedMagic & 0xFF,
      (_encryptedMagic >> 8) & 0xFF,
      (_encryptedMagic >> 16) & 0xFF,
      (_encryptedMagic >> 24) & 0xFF,
    ];
    return [...magic, ...encrypted.bytes];
  }

  List<int> _decryptBytes(List<int> data) {
    final key = Key.fromUtf8(BackupEnv.encryptKey);
    final iv = IV.fromUtf8(BackupEnv.encryptIv);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final decrypted = encrypter.decryptBytes(Encrypted(Uint8List.fromList(data)), iv: iv);
    return decrypted;
  }
}
