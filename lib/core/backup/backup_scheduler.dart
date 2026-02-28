import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../database/daos/app_settings_dao.dart';

/// Schedules periodic backups via WorkManager.
///
/// When [AppSettingsDao.keyScheduledBackupsEnabled] is true, runs weekly.
/// Backup files are stored in app documents/backups/. Drive upload is a future enhancement.
@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _taskName) return false;
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(appDocDir.path, 'master_of_coin.db');
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) return false;

      final backupsDir = Directory(p.join(appDocDir.path, 'backups'));
      if (!await backupsDir.exists()) await backupsDir.create(recursive: true);

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = p.join(backupsDir.path, 'backup_$timestamp.mocbackup');
      await dbFile.copy(backupPath);
      return true;
    } catch (_) {
      return false;
    }
  });
}

const String _taskName = 'masterOfCoinBackup';

/// Registers or cancels the weekly backup task.
class BackupScheduler {
  BackupScheduler({required AppSettingsDao settingsDao}) : _settingsDao = settingsDao;

  final AppSettingsDao _settingsDao;

  Future<void> updateSchedule() async {
    final enabled = await _settingsDao.getBool(
      AppSettingsDao.keyScheduledBackupsEnabled,
      defaultValue: false,
    );
    if (enabled) {
      await Workmanager().registerPeriodicTask(
        'masterOfCoinBackup',
        _taskName,
        frequency: const Duration(days: 7),
      );
    } else {
      await Workmanager().cancelByUniqueName('masterOfCoinBackup');
    }
  }
}
