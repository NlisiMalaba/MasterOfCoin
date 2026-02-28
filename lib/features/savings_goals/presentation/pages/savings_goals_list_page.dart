import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/database/daos/savings_goal_dao.dart';
import '../../../../core/database/daos/savings_usage_dao.dart' show SavingsUsageDao, SavingsUsageRow;
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../shared/domain/currency.dart';
import '../../domain/entity/savings_goal.dart';

class SavingsGoalsListPage extends StatefulWidget {
  const SavingsGoalsListPage({super.key});

  @override
  State<SavingsGoalsListPage> createState() => _SavingsGoalsListPageState();
}

class _SavingsGoalsListPageState extends State<SavingsGoalsListPage> {
  late SavingsGoalDao _dao;
  late SavingsUsageDao _usageDao;
  List<SavingsGoal> _goals = [];
  double _totalWithdrawn = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _dao = getIt<SavingsGoalDao>();
    _usageDao = getIt<SavingsUsageDao>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final goals = await _dao.getAll();
    final usages = await _usageDao.getAllWithGoalNames();
    final withdrawn = usages.fold<double>(0, (sum, u) => sum + u.amount);
    setState(() {
      _goals = goals;
      _totalWithdrawn = withdrawn;
      _loading = false;
    });
  }

  Future<void> _showWithdraw(BuildContext context, SavingsGoal goal) async {
    final amountController = TextEditingController();
    final purposeController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Withdraw from "${goal.name}"'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Available: ${CurrencyFormatter.format(goal.currentAmount, goal.currency)}',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '${goal.currency.symbol} ',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: purposeController,
                decoration: const InputDecoration(
                  labelText: 'Where did the money go?',
                  hintText: 'e.g. Bought new phone',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              final purpose = purposeController.text.trim();
              if (amount == null || amount <= 0 || purpose.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter amount and purpose')),
                );
                return;
              }
              if (amount > goal.currentAmount) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Amount exceeds available balance')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final amount = double.tryParse(amountController.text)!;
      final purpose = purposeController.text.trim();
      final now = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final row = SavingsUsageRow(
        id: const Uuid().v4(),
        savingsGoalId: goal.id,
        amount: amount,
        purpose: purpose,
        date: now,
        createdAt: now,
      );
      await _usageDao.insert(row);
      _load();
    }
  }

  Future<void> _deleteGoal(SavingsGoal goal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete "${goal.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _dao.delete(goal.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          const ThemeToggleButton(),
          TextButton.icon(
            onPressed: () => context.push('/savings-usage'),
            icon: const Icon(Icons.shopping_bag_outlined, size: 20),
            label: const Text('Usage'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.savings, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No savings goals yet', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => _showAddGoal(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Goal'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SavingsSummaryCard(
                        goals: _goals,
                        totalWithdrawn: _totalWithdrawn,
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(_goals.length, (i) {
                        final g = _goals[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildGoalCard(context, g),
                        );
                      }),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, SavingsGoal g) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    g.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) {
                    if (v == 'edit') _showAddGoal(context, goal: g);
                    if (v == 'delete') _deleteGoal(g);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: g.progressPercent,
              backgroundColor: Colors.grey[300],
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text(
              '${CurrencyFormatter.format(g.currentAmount, g.currency)} / ${CurrencyFormatter.format(g.targetAmount, g.currency)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (g.deadlineDate != null)
              Text(
                'Due: ${_formatDate(g.deadlineDate!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/transactions/add',
                      extra: {'savingsGoalId': g.id},
                    ).then((_) => _load()),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Top up'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: g.currentAmount > 0
                        ? () => _showWithdraw(context, g)
                        : null,
                    icon: const Icon(Icons.remove, size: 18),
                    label: const Text('Withdraw'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(int unixSec) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _showAddGoal(BuildContext context, {SavingsGoal? goal}) async {
    final nameController = TextEditingController(text: goal?.name ?? '');
    final amountController = TextEditingController(
      text: goal?.targetAmount.toStringAsFixed(2) ?? '',
    );
    Currency currency = goal?.currency ?? Currency.usd;
    DateTime? deadline = goal?.deadlineDate != null
        ? DateTime.fromMillisecondsSinceEpoch(goal!.deadlineDate! * 1000)
        : null;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.savings_outlined,
                        size: 28,
                        color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        goal != null ? 'Edit savings goal' : 'New savings goal',
                        style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'What are you saving for?',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. New phone, Laptop, Vacation',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Target amount',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: '${currency.symbol} ',
                    prefixStyle: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Currency',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _CurrencyOption(
                        value: Currency.usd,
                        selected: currency == Currency.usd,
                        onTap: () => setModalState(() => currency = Currency.usd),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CurrencyOption(
                        value: Currency.zwg,
                        selected: currency == Currency.zwg,
                        onTap: () => setModalState(() => currency = Currency.zwg),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Deadline (optional)',
                  style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () async {
                      final pick = await showDatePicker(
                        context: ctx,
                        initialDate: deadline ?? DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (pick != null) setModalState(() => deadline = pick);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 22,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              deadline != null
                                  ? '${deadline!.day}/${deadline!.month}/${deadline!.year}'
                                  : 'Pick a target date',
                              style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                                    color: deadline != null
                                        ? Theme.of(ctx).colorScheme.onSurface
                                        : Theme.of(ctx).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          if (deadline != null)
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => setModalState(() => deadline = null),
                              style: IconButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.all(4),
                              ),
                            )
                          else
                            Icon(
                              Icons.chevron_right,
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {
                          final amount = double.tryParse(amountController.text);
                          if (nameController.text.trim().isEmpty || amount == null || amount <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Enter name and valid amount')),
                            );
                            return;
                          }
                          Navigator.pop(ctx, true);
                        },
                        child: const Text('Save goal'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) return;
      final now = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final id = goal?.id ?? const Uuid().v4();
      final sg = SavingsGoal(
        id: id,
        name: nameController.text.trim(),
        targetAmount: amount,
        currency: currency,
        currentAmount: goal?.currentAmount ?? 0,
        deadlineDate: deadline != null ? (deadline!.millisecondsSinceEpoch / 1000).round() : null,
        createdAt: goal?.createdAt ?? now,
        updatedAt: now,
      );
      if (goal != null) {
        await _dao.update(sg);
      } else {
        await _dao.insert(sg);
      }
      _load();
    }
  }
}

class _CurrencyOption extends StatelessWidget {
  const _CurrencyOption({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final Currency value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? primary : surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? primary
                  : onSurfaceVariant.withValues(alpha: 0.4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              value.code,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : onSurface,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SavingsSummaryCard extends StatelessWidget {
  const _SavingsSummaryCard({
    required this.goals,
    required this.totalWithdrawn,
  });

  final List<SavingsGoal> goals;
  final double totalWithdrawn;

  @override
  Widget build(BuildContext context) {
    final totalSaved = goals.fold<double>(0, (s, g) => s + g.currentAmount);
    final totalTarget = goals.fold<double>(0, (s, g) => s + g.targetAmount);
    final progress =
        totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Savings overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total saved',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        goals.isNotEmpty
                            ? CurrencyFormatter.format(
                                totalSaved,
                                goals.first.currency,
                              )
                            : '\$0.00',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (totalWithdrawn > 0)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total used',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          goals.isNotEmpty
                              ? CurrencyFormatter.format(
                                  totalWithdrawn,
                                  goals.first.currency,
                                )
                              : '\$0.00',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }
}
