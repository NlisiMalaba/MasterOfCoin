import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/app_state.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

class MasterOfCoinApp extends StatefulWidget {
  const MasterOfCoinApp({super.key});

  @override
  State<MasterOfCoinApp> createState() => _MasterOfCoinAppState();
}

class _MasterOfCoinAppState extends State<MasterOfCoinApp> {
  late final ThemeController _themeController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _themeController = getIt<ThemeController>();
    _themeController.addListener(_onThemeChanged);
    _router = AppRouter.createRouter(
      isOnboardingComplete: () => AppState.isOnboardingComplete,
    );
  }

  void _onThemeChanged() => setState(() {});

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Master of Coin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeController.value,
      routerConfig: _router,
    );
  }
}
