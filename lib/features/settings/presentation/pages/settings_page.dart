import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/database/daos/app_settings_dao.dart';
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
    setState(() {
      _defaultCurrency =
          currencyCode != null ? Currency.fromCode(currencyCode) : Currency.usd;
      _exchangeRate = rate ?? 13.66;
      _incomeSources = sources;
      _expenseCategories = categories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _defaultCurrency == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('General', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  title: const Text('Default Currency'),
                  subtitle: Text(_defaultCurrency!.code),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCurrencyPicker(context),
                ),
                ListTile(
                  title: const Text('Exchange Rate (ZWG per USD)'),
                  subtitle: Text(_exchangeRate?.toStringAsFixed(2) ?? '—'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showExchangeRateDialog(context),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Income Sources', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  title: const Text('Manage Income Sources'),
                  subtitle: Text('${_incomeSources.length} sources'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showIncomeSourcesList(context),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Expense Categories', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  title: const Text('Manage Categories'),
                  subtitle: Text('${_expenseCategories.length} categories'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showExpenseCategoriesList(context),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('More', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  title: const Text('Budgets'),
                  subtitle: const Text('Monthly budget allocations'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/budgets'),
                ),
                ListTile(
                  title: const Text('Recurring Templates'),
                  subtitle: const Text('Weekly and monthly templates'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/recurring'),
                ),
              ],
            ),
    );
  }

  Future<void> _showIncomeSourcesList(BuildContext context) async {
    final sources = await _incomeDao.getAll(activeOnly: false);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Income Sources', style: Theme.of(context).textTheme.titleLarge),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: sources.length,
                itemBuilder: (context, i) {
                  final s = sources[i];
                  return ListTile(
                    title: Text(s.name),
                    subtitle: Text('${s.currency.code}'),
                    trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await _incomeDao.delete(s.id);
                              _loadSettings();
                              if (mounted) Navigator.pop(context);
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExpenseCategoriesList(BuildContext context) async {
    final categories = await _expenseDao.getAll();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Expense Categories', style: Theme.of(context).textTheme.titleLarge),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: categories.length,
                itemBuilder: (context, i) {
                  final c = categories[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: c.color,
                      child: Icon(c.iconName != null ? _iconForName(c.iconName!) : Icons.category, color: Colors.white, size: 20),
                    ),
                    title: Text(c.name),
                    trailing: c.isSystem
                        ? const Chip(label: Text('Default', style: TextStyle(fontSize: 10)))
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await _expenseDao.delete(c.id);
                              _loadSettings();
                              if (mounted) Navigator.pop(context);
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForName(String name) {
    const map = {
      'shopping_cart': Icons.shopping_cart,
      'directions_car': Icons.directions_car,
      'checkroom': Icons.checkroom,
      'bolt': Icons.bolt,
      'phone_android': Icons.phone_android,
      'restaurant': Icons.restaurant,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'movie': Icons.movie,
      'more_horiz': Icons.more_horiz,
    };
    return map[name] ?? Icons.category;
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    final picked = await showDialog<Currency>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Currency.values.map((c) {
            return ListTile(
              title: Text('${c.symbol} ${c.code}'),
              onTap: () => Navigator.pop(context, c),
            );
          }).toList(),
        ),
      ),
    );
    if (picked != null) {
      await _settingsDao.setString(AppSettingsDao.keyDefaultCurrency, picked.code);
      setState(() => _defaultCurrency = picked);
    }
  }

  Future<void> _showExchangeRateDialog(BuildContext context) async {
    final controller = TextEditingController(text: _exchangeRate?.toString() ?? '');
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exchange Rate'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'ZWG per 1 USD',
            hintText: 'e.g. 13.66',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null && v > 0) Navigator.pop(context, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _settingsDao.setDouble(AppSettingsDao.keyExchangeRate, result);
      setState(() => _exchangeRate = result);
    }
  }
}
