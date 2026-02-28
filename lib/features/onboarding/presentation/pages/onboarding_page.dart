import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_state.dart';
import '../../../../core/backup/backup_restore_result.dart';
import '../../../../core/backup/backup_restore_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/database/daos/app_settings_dao.dart';
import '../../../../shared/domain/currency.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  Currency _selectedCurrency = Currency.usd;
  bool _isLoading = false;
  bool _isRestoring = false;

  Future<void> _restoreFromBackup() async {
    setState(() => _isRestoring = true);
    try {
      final result = await getIt<BackupRestoreService>().restore();
      if (!mounted) return;
      switch (result) {
        case RestoreSuccess():
          await getIt<AppSettingsDao>().setBool(
            AppSettingsDao.keyOnboardingComplete,
            true,
          );
          AppState.setOnboardingComplete(true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data restored. Welcome back!')),
            );
            context.go('/');
          }
        case BackupRestoreFailure(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        case BackupRestoreCancelled():
          break;
        case BackupSuccess():
          break;
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final settings = getIt<AppSettingsDao>();
      await settings.setString(AppSettingsDao.keyDefaultCurrency, _selectedCurrency.code);
      await settings.setBool(AppSettingsDao.keyOnboardingComplete, true);
      AppState.setOnboardingComplete(true);
      if (mounted) {
        context.go('/');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Master of Coin',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your personal finance companion for Zimbabwe.\nTrack income, expenses, and savings in USD and ZWG.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _isRestoring
                    ? null
                    : _restoreFromBackup,
                icon: _isRestoring
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download, size: 20),
                label: Text(_isRestoring ? 'Restoring…' : 'Restore from backup'),
              ),
              const Spacer(),
              Text(
                'Choose your default currency',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: Currency.values.map((c) {
                  final isSelected = _selectedCurrency == c;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text('${c.symbol} ${c.code}'),
                        onSelected: (_) => setState(() => _selectedCurrency = c),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _completeOnboarding,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Get Started'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
