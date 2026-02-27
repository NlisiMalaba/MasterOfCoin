import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation shell for main app tabs.
/// Shows icons only (Home, Transactions, Savings, Analytics, Settings).
/// FAB for adding transactions is shown only on Home and Transactions.
class MainShell extends StatelessWidget {
  static const int _homeIndex = 0;
  static const int _transactionsIndex = 1;

  static bool _showFabForIndex(int index) =>
      index == _homeIndex || index == _transactionsIndex;
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Transactions'),
          NavigationDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings), label: 'Savings'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      floatingActionButton: _showFabForIndex(navigationShell.currentIndex)
          ? FloatingActionButton(
              onPressed: () => context.push('/transactions/add'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
