import 'package:flutter/material.dart';

import '../database/daos/app_settings_dao.dart';

/// Manages app theme mode (light/dark) with persistence.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController(this._dao) : super(ThemeMode.light);

  final AppSettingsDao _dao;

  Future<void> load() async {
    final stored = await _dao.getString(AppSettingsDao.keyThemeMode);
    if (stored == 'dark') {
      value = ThemeMode.dark;
    } else if (stored == 'system') {
      value = ThemeMode.system;
    } else {
      value = ThemeMode.light;
    }
  }

  Future<void> toggle() async {
    final next = value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    value = next;
    final key = next == ThemeMode.light ? 'light' : 'dark';
    await _dao.setString(AppSettingsDao.keyThemeMode, key);
  }
}
