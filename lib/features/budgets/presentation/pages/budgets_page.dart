import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/database/daos/budget_allocation_dao.dart';
import '../../../../core/database/daos/transaction_dao.dart';
import '../../../../core/database/daos/expense_category_dao.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../shared/domain/currency.dart';
import '../../domain/entity/budget_allocation.dart';
import '../../../expenses/domain/entity/expense_category.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  late BudgetAllocationDao _budgetDao;
  late TransactionDao _txDao;
  late ExpenseCategoryDao _categoryDao;

  List<ExpenseCategory> _categories = [];
  List<BudgetAllocation> _allocations = [];
  Currency _currency = Currency.usd;
  DateTime _selectedMonth = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _budgetDao = getIt<BudgetAllocationDao>();
    _txDao = getIt<TransactionDao>();
    _categoryDao = getIt<ExpenseCategoryDao>();
    _load();
  }

  int get _periodStart => _selectedMonth.startOfMonth.toUnixSeconds;
  int get _periodEnd => _selectedMonth.endOfMonth.toUnixSeconds;

  Future<void> _load() async {
    setState(() => _loading = true);
    final categories = await _categoryDao.getAll();
    final allocations = await _budgetDao.getForPeriod(_periodStart, _periodEnd);
    setState(() {
      _categories = categories;
      _allocations = allocations;
      _loading = false;
    });
  }

  Future<double> _getSpentForCategory(String categoryId) async {
    return _txDao.sumExpensesByCategory(
      categoryId,
      _currency.code,
      startDate: _periodStart,
      endDate: _periodEnd,
    );
  }

  Future<void> _setBudget(ExpenseCategory category) async {
    final existingList = _allocations.where((a) => a.categoryId == category.id).toList();
    final existing = existingList.isNotEmpty ? existingList.first : null;
    final controller = TextEditingController(
      text: existing?.amount.toStringAsFixed(2) ?? '0',
    );

    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Budget for ${category.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount (${_currency.symbol})',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              if (v != null && v >= 0) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (amount != null) {
      final now = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final id = existing?.id ?? '${category.id}_${_periodStart}';
      final alloc = BudgetAllocation(
        id: id,
        categoryId: category.id,
        amount: amount,
        currency: _currency,
        periodStart: _periodStart,
        periodEnd: _periodEnd,
        createdAt: existing?.createdAt ?? now,
      );
      await _budgetDao.insert(alloc);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final pick = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (pick != null) {
                setState(() => _selectedMonth = pick);
                _load();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        '${_selectedMonth.month}/${_selectedMonth.year}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      SegmentedButton<Currency>(
                        segments: Currency.values
                            .map((c) => ButtonSegment(value: c, label: Text(c.code)))
                            .toList(),
                        selected: {_currency},
                        onSelectionChanged: (s) {
                          setState(() {
                            _currency = s.first;
                            _load();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      final allocList = _allocations.where((a) => a.categoryId == cat.id).toList();
                      final alloc = allocList.isNotEmpty ? allocList.first : null;
                      return FutureBuilder<double>(
                        future: _getSpentForCategory(cat.id),
                        builder: (ctx, snap) {
                          final spent = snap.data ?? 0;
                          final budget = alloc?.amount ?? 0;
                          final percent = budget > 0 ? (spent / budget).clamp(0.0, 2.0) : 0.0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: cat.color,
                                child: Icon(Icons.category, color: Colors.white, size: 20),
                              ),
                              title: Text(cat.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: percent > 1 ? 1 : percent,
                                    backgroundColor: Colors.grey[300],
                                    color: percent >= 1 ? Colors.red : Colors.green,
                                  ),
                                  Text(
                                    '${CurrencyFormatter.format(spent, _currency)} / ${CurrencyFormatter.format(budget, _currency)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _setBudget(cat),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
