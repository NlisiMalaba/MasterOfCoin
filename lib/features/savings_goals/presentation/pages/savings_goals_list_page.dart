import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/database/daos/savings_goal_dao.dart';
import '../../../../core/database/daos/savings_usage_dao.dart' show SavingsUsageDao, SavingsUsageRow;
import '../../../../core/utils/currency_formatter.dart';
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(goal != null ? 'Edit Goal' : 'New Savings Goal',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Target Amount'),
                ),
                const SizedBox(height: 16),
                SegmentedButton<Currency>(
                  segments: Currency.values.map((c) => ButtonSegment(value: c, label: Text(c.code))).toList(),
                  selected: {currency},
                  onSelectionChanged: (s) => setModalState(() => currency = s.first),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(deadline != null
                      ? 'Due: ${deadline!.day}/${deadline!.month}/${deadline!.year}'
                      : 'Set deadline'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final pick = await showDatePicker(
                      context: ctx,
                      initialDate: deadline ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (pick != null) setModalState(() => deadline = pick);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(
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
                      child: const Text('Save'),
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
