import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/app_state.dart';
import 'core/backup/backup_scheduler.dart';
import 'core/di/injection.dart';
import 'core/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(
    backupCallbackDispatcher,
    isInDebugMode: false,
  );
  await configureDependencies();
  await AppState.load();
  await getIt<ThemeController>().load();
  await getIt<BackupScheduler>().updateSchedule();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MasterOfCoinApp());
}
