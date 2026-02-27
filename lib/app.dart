import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class MasterOfCoinApp extends StatelessWidget {
  const MasterOfCoinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Master of Coin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.createRouter(
        isOnboardingComplete: () => AppState.isOnboardingComplete,
      ),
    );
  }
}
