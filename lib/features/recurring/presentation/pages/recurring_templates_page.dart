import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/database/daos/recurring_template_dao.dart';
import '../../../../core/widgets/filter_segment_buttons.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../core/database/daos/transaction_dao.dart';
import '../../../../core/database/daos/income_source_dao.dart';
import '../../../../core/database/daos/expense_category_dao.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/domain/currency.dart';
import '../../../../shared/domain/transaction_type.dart';
import '../../../transactions/domain/entity/transaction.dart';

class RecurringTemplatesPage extends StatefulWidget {
  const RecurringTemplatesPage({super.key});

  @override
  State<RecurringTemplatesPage> createState() => _RecurringTemplatesPageState();
}

class _RecurringTemplatesPageState extends State<RecurringTemplatesPage> {
  late RecurringTemplateDao _templateDao;
  late TransactionDao _txDao;
  late IncomeSourceDao _incomeDao;
  late ExpenseCategoryDao _expenseDao;

  List<RecurringTemplateRow> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _templateDao = getIt<RecurringTemplateDao>();
    _txDao = getIt<TransactionDao>();
    _incomeDao = getIt<IncomeSourceDao>();
    _expenseDao = getIt<ExpenseCategoryDao>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _templateDao.getAll();
    if (mounted) {
      setState(() {
        _templates = list;
        _loading = false;
      });
    }
  }

  Future<void> _applyTemplate(RecurringTemplateRow t) async {
    final now = DateTime.now();
    final dateSec = (now.millisecondsSinceEpoch / 1000).round();
    final tx = Transaction(
      id: const Uuid().v4(),
      type: t.type == 'income' ? TransactionType.income : TransactionType.expense,
      amount: t.amount,
      currency: t.currency,
      date: dateSec,
      createdAt: dateSec,
      categoryId: t.categoryId,
      note: t.note,
    );
    await _txDao.insert(TransactionInsert(
      id: tx.id,
      type: tx.type,
      amount: tx.amount,
      currency: tx.currency,
      date: tx.date,
      createdAt: tx.createdAt,
      categoryId: tx.categoryId,
      note: tx.note,
    ));
    await _templateDao.update(RecurringTemplateRow(
      id: t.id,
      type: t.type,
      amount: t.amount,
      currency: t.currency,
      categoryId: t.categoryId,
      note: t.note,
      recurrence: t.recurrence,
      lastAppliedDate: dateSec,
      createdAt: t.createdAt,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added')),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: const [ThemeToggleButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? _EmptyState(onAdd: () => _showForm(context))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    itemCount: _templates.length,
                    itemBuilder: (context, i) {
                      final t = _templates[i];
                      return _TemplateCard(
                        template: t,
                        onApply: () => _applyTemplate(t),
                        onEdit: () => _showForm(context, existing: t),
                        onDelete: () async {
                          await _templateDao.delete(t.id);
                          await _load();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Template deleted')),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Template'),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, {RecurringTemplateRow? existing}) async {
    TransactionType type = existing != null
        ? (existing.type == 'income' ? TransactionType.income : TransactionType.expense)
        : TransactionType.expense;
    Currency currency = existing?.currency ?? Currency.usd;
    final amountController = TextEditingController(
      text: existing?.amount.toStringAsFixed(2) ?? '',
    );
    final noteController = TextEditingController(text: existing?.note ?? '');
    String recurrence = existing?.recurrence ?? 'monthly';

    final result = await showModalBottomSheet<Map<String, dynamic>>(
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
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.repeat,
                        size: 28,
                        color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        existing != null ? 'Edit Template' : 'New Recurring Template',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilterSegmentButtons<TransactionType>(
                  options: [TransactionType.income, TransactionType.expense],
                  selected: type,
                  onChanged: (t) => setModalState(() => type = t),
                  labelBuilder: (t) => t.name[0].toUpperCase() + t.name.substring(1),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '${currency.symbol} ',
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'e.g. Monthly salary, Rent',
                  ),
                ),
                const SizedBox(height: 16),
                FilterSegmentButtons<Currency>(
                  options: Currency.values,
                  selected: currency,
                  onChanged: (c) => setModalState(() => currency = c),
                  labelBuilder: (c) => c.code,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: recurrence,
                  decoration: const InputDecoration(labelText: 'Repeat'),
                  items: const [
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  ],
                  onChanged: (v) => setModalState(() => recurrence = v ?? 'monthly'),
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
                          final amount = double.tryParse(amountController.text);
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Enter a valid amount')),
                            );
                            return;
                          }
                          Navigator.pop(ctx, {
                            'type': type,
                            'currency': currency,
                            'amount': amount,
                            'note': noteController.text.trim(),
                            'recurrence': recurrence,
                          });
                        },
                        child: const Text('Save'),
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

    if (result != null && mounted) {
      final type = result['type'] as TransactionType;
      final currency = result['currency'] as Currency;
      final amount = result['amount'] as double;
      final note = result['note'] as String;
      final recurrence = result['recurrence'] as String;

      String? categoryId;
      final sources = await _incomeDao.getByCurrency(currency);
      final categories = await _expenseDao.getAll();
      if (type == TransactionType.income && sources.isNotEmpty) {
        categoryId = sources.first.id;
      }
      if (type == TransactionType.expense && categories.isNotEmpty) {
        categoryId = categories.first.id;
      }

      final now = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final row = RecurringTemplateRow(
        id: existing?.id ?? const Uuid().v4(),
        type: type.name,
        amount: amount,
        currency: currency,
        categoryId: categoryId,
        note: note.isEmpty ? null : note,
        recurrence: recurrence,
        lastAppliedDate: existing?.lastAppliedDate,
        createdAt: existing?.createdAt ?? now,
      );
      await _templateDao.insert(row);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(existing != null ? 'Updated' : 'Template added')),
        );
      }
    }
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onApply,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringTemplateRow template;
  final VoidCallback onApply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = template.type == 'income';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isIncome
                            ? Colors.green
                            : Theme.of(context).colorScheme.error)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncome ? Icons.trending_up : Icons.trending_down,
                    color: isIncome ? Colors.green : Theme.of(context).colorScheme.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.note?.isNotEmpty == true
                            ? template.note!
                            : '${template.type == 'income' ? 'Income' : 'Expense'} • ${template.currency.code}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${CurrencyFormatter.format(template.amount, template.currency)} • ${template.recurrence}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onApply,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 8),
                    Text('Add transaction now'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.repeat,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No recurring templates',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create weekly or monthly templates for salaries, rent, and more',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Template'),
            ),
          ],
        ),
      ),
    );
  }
}
