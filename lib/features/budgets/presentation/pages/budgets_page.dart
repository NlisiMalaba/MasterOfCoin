import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/database/daos/budget_allocation_dao.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../core/database/daos/transaction_dao.dart';
import '../../../../core/database/daos/expense_category_dao.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../shared/domain/currency.dart';
import '../../domain/entity/budget_allocation.dart';
import '../../../expenses/domain/entity/expense_category.dart';

const _iconMap = {
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
  'home': Icons.home,
  'category': Icons.category,
};

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
    if (mounted) {
      setState(() {
        _categories = categories;
        _allocations = allocations;
        _loading = false;
      });
    }
  }

  Future<double> _getSpentForCategory(String categoryId) async {
    return _txDao.sumExpensesByCategory(
      categoryId,
      _currency.code,
      startDate: _periodStart,
      endDate: _periodEnd,
    );
  }

  IconData _iconForCategory(ExpenseCategory cat) =>
      _iconMap[cat.iconName] ?? Icons.category;

  Future<void> _setBudget(ExpenseCategory category) async {
    final existingList =
        _allocations.where((a) => a.categoryId == category.id).toList();
    final existing = existingList.isNotEmpty ? existingList.first : null;
    final controller = TextEditingController(
      text: existing?.amount.toStringAsFixed(2) ?? '0',
    );

    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: category.color,
                  child: Icon(_iconForCategory(category), color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Budget for ${category.name}',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${_currency.symbol} ',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      final v = double.tryParse(controller.text);
                      if (v != null && v >= 0) Navigator.pop(ctx, v);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (amount != null) {
      final now = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final id = existing?.id ?? '${category.id}_$_periodStart';
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
      await _load();
    }
  }

  String get _monthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          const ThemeToggleButton(),
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
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _monthLabel,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          SegmentedButton<Currency>(
                            style: ButtonStyle(
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            segments: Currency.values
                                .map((c) => ButtonSegment(
                                      value: c,
                                      label: Text('${c.symbol} ${c.code}'),
                                    ))
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
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final cat = _categories[i];
                          final allocList =
                              _allocations.where((a) => a.categoryId == cat.id).toList();
                          final alloc = allocList.isNotEmpty ? allocList.first : null;
                          return FutureBuilder<double>(
                            future: _getSpentForCategory(cat.id),
                            builder: (ctx, snap) {
                              final spent = snap.data ?? 0;
                              final budget = alloc?.amount ?? 0;
                              final percent = budget > 0
                                  ? (spent / budget).clamp(0.0, 2.0)
                                  : 0.0;
                              return _BudgetCard(
                                category: cat,
                                spent: spent,
                                budget: budget,
                                currency: _currency,
                                percent: percent,
                                icon: _iconForCategory(cat),
                                onEdit: () => _setBudget(cat),
                              );
                            },
                          );
                        },
                        childCount: _categories.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.category,
    required this.spent,
    required this.budget,
    required this.currency,
    required this.percent,
    required this.icon,
    required this.onEdit,
  });

  final ExpenseCategory category;
  final double spent;
  final double budget;
  final Currency currency;
  final double percent;
  final IconData icon;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isOver = percent >= 1;
    final progressColor = isOver
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: category.color.withValues(alpha: 0.2),
                    child: Icon(icon, color: category.color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${CurrencyFormatter.format(spent, currency)} / ${CurrencyFormatter.format(budget, currency)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percent > 1 ? 1 : percent,
                  minHeight: 8,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              if (budget > 0 && percent >= 0.8)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    percent >= 1
                        ? '${((percent - 1) * 100).toStringAsFixed(0)}% over budget'
                        : 'Approaching limit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
