import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app_state.dart';
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
