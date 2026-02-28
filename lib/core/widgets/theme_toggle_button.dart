import 'package:flutter/material.dart';

import '../di/injection.dart';
import '../theme/theme_controller.dart';

/// Icon button that toggles between light and dark theme.
/// Place in AppBar actions for consistent placement across all pages.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = getIt<ThemeController>();
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);
        return IconButton(
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          onPressed: () => controller.toggle(),
          tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
        );
      },
    );
  }
}
