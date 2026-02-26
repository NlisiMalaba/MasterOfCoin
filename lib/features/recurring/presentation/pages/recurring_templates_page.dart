import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/database/daos/recurring_template_dao.dart';
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
    setState(() {
      _templates = list;
      _loading = false;
    });
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
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.repeat, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No recurring templates', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => _showAddTemplate(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Template'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _templates.length,
                    itemBuilder: (context, i) {
                      final t = _templates[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(t.note ?? '${t.type} - ${t.currency.code}'),
                          subtitle: Text(
                            '${CurrencyFormatter.format(t.amount, t.currency)} • ${t.recurrence}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton.tonal(
                                onPressed: () => _applyTemplate(t),
                                child: const Text('Add now'),
                              ),
                              PopupMenuButton(
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                                onSelected: (v) async {
                                  if (v == 'delete') {
                                    await _templateDao.delete(t.id);
                                    _load();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTemplate(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddTemplate(BuildContext context) async {
    TransactionType type = TransactionType.expense;
    Currency currency = Currency.usd;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String recurrence = 'monthly';

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('New Recurring Template', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(value: TransactionType.income, label: Text('Income')),
                      ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                    ],
                    selected: {type},
                    onSelectionChanged: (s) => setModalState(() => type = s.first),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Note'),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<Currency>(
                    segments: Currency.values.map((c) => ButtonSegment(value: c, label: Text(c.code))).toList(),
                    selected: {currency},
                    onSelectionChanged: (s) => setModalState(() => currency = s.first),
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () {
                          final amount = double.tryParse(amountController.text);
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Enter valid amount')),
                            );
                            return;
                          }
                          Navigator.pop(ctx, {
                            'type': type,
                            'currency': currency,
                            'amount': amount,
                            'note': noteController.text,
                            'recurrence': recurrence,
                          });
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result != null) {
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
        id: const Uuid().v4(),
        type: type.name,
        amount: amount,
        currency: currency,
        categoryId: categoryId,
        note: note.isEmpty ? null : note,
        recurrence: recurrence,
        createdAt: now,
      );
      await _templateDao.insert(row);
      _load();
    }
  }
}
