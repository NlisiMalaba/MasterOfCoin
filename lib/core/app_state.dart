import 'package:flutter/foundation.dart';

import 'database/daos/app_settings_dao.dart';
import 'di/injection.dart';

/// Holds app-wide state that must be available synchronously (e.g. for router redirect).
class AppState {
  AppState._();

  static bool _onboardingComplete = false;
  static bool get isOnboardingComplete => _onboardingComplete;

  static Future<void> load() async {
    final settings = getIt<AppSettingsDao>();
    _onboardingComplete = await settings.getBool(
      AppSettingsDao.keyOnboardingComplete,
      defaultValue: false,
    );
  }

  static void setOnboardingComplete(bool value) {
    _onboardingComplete = value;
  }
}
