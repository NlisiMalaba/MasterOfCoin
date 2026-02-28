import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/database/daos/app_settings_dao.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../core/database/daos/income_source_dao.dart';
import '../../../../core/database/daos/expense_category_dao.dart';
import '../../../../shared/domain/currency.dart';
import '../../../income/domain/entity/income_source.dart';
import '../../../expenses/domain/entity/expense_category.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppSettingsDao _settingsDao;
  late IncomeSourceDao _incomeDao;
  late ExpenseCategoryDao _expenseDao;
  Currency? _defaultCurrency;
  double? _exchangeRate;
  List<IncomeSource> _incomeSources = [];
  List<ExpenseCategory> _expenseCategories = [];

  @override
  void initState() {
    super.initState();
    _settingsDao = getIt<AppSettingsDao>();
    _incomeDao = getIt<IncomeSourceDao>();
    _expenseDao = getIt<ExpenseCategoryDao>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final currencyCode = await _settingsDao.getString(AppSettingsDao.keyDefaultCurrency);
    final rate = await _settingsDao.getDouble(AppSettingsDao.keyExchangeRate);
    final sources = await _incomeDao.getAll(activeOnly: false);
    final categories = await _expenseDao.getAll();
    if (mounted) {
      setState(() {
        _defaultCurrency =
            currencyCode != null ? Currency.fromCode(currencyCode) : Currency.usd;
        _exchangeRate = rate ?? 1.00;
        _incomeSources = sources;
        _expenseCategories = categories;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [ThemeToggleButton()],
      ),
      body: _defaultCurrency == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _SettingsSection(
                    icon: Icons.tune,
                    title: 'General',
                    children: [
                      _SettingsTile(
                        icon: Icons.currency_exchange,
                        title: 'Default Currency',
                        subtitle: '${_defaultCurrency!.symbol} ${_defaultCurrency!.code}',
                        onTap: () => _showCurrencyPicker(context),
                      ),
                      const SizedBox(height: 12),
                      _SettingsTile(
                        icon: Icons.trending_up,
                        title: 'Exchange Rate',
                        subtitle: '1 USD = ${_exchangeRate?.toStringAsFixed(2) ?? '—'} ZWG',
                        onTap: () => _showExchangeRateDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    icon: Icons.category,
                    title: 'Income & Categories',
                    children: [
                      _SettingsTile(
                        icon: Icons.account_balance_wallet,
                        title: 'Income Sources',
                        subtitle: '${_incomeSources.length} sources',
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => context.push('/income-sources'),
                      ),
                      const SizedBox(height: 12),
                      _SettingsTile(
                        icon: Icons.label_outline,
                        title: 'Expense Categories',
                        subtitle: '${_expenseCategories.length} categories',
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => context.push('/expense-categories'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    icon: Icons.dashboard_customize,
                    title: 'Planning',
                    children: [
                      _SettingsTile(
                        icon: Icons.pie_chart_outline,
                        title: 'Budgets',
                        subtitle: 'Monthly spending limits by category',
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => context.push('/budgets'),
                      ),
                      const SizedBox(height: 12),
                      _SettingsTile(
                        icon: Icons.repeat,
                        title: 'Recurring Templates',
                        subtitle: 'Weekly and monthly transactions',
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => context.push('/recurring'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<Currency>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Default Currency',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            ...Currency.values.map((c) {
              final selected = _defaultCurrency == c;
              return ListTile(
                leading: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected
                      ? Theme.of(ctx).colorScheme.primary
                      : Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
                title: Text('${c.symbol} ${c.code}'),
                onTap: () => Navigator.pop(ctx, c),
              );
            }),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      await _settingsDao.setString(AppSettingsDao.keyDefaultCurrency, picked.code);
      setState(() => _defaultCurrency = picked);
    }
  }

  Future<void> _showExchangeRateDialog(BuildContext context) async {
    final controller = TextEditingController(text: _exchangeRate?.toString() ?? '');
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exchange Rate'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'ZWG per 1 USD',
            hintText: 'e.g. 1.00',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      await _settingsDao.setDouble(AppSettingsDao.keyExchangeRate, result);
      setState(() => _exchangeRate = result);
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
