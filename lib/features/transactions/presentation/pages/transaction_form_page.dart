import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/database/daos/transaction_dao.dart'
    show TransactionDao, TransactionInsert;
import '../../../../core/database/daos/income_source_dao.dart';
import '../../../../core/database/daos/expense_category_dao.dart';
import '../../../../core/database/daos/savings_goal_dao.dart';
import '../../../../core/utils/transaction_mappers.dart';
import '../../../../shared/domain/currency.dart';
import '../../../../shared/domain/transaction_type.dart';
import '../../domain/entity/transaction.dart';

class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({super.key, this.transactionId});

  final String? transactionId;

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  late TransactionDao _txDao;
  late IncomeSourceDao _incomeDao;
  late ExpenseCategoryDao _expenseDao;
  late SavingsGoalDao _savingsDao;

  TransactionType _type = TransactionType.expense;
  Currency _currency = Currency.usd;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  String? _categoryId;
  String? _savingsGoalId;

  List<dynamic> _incomeSources = [];
  List<dynamic> _expenseCategories = [];
  List<dynamic> _savingsGoals = [];
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _txDao = getIt<TransactionDao>();
    _incomeDao = getIt<IncomeSourceDao>();
    _expenseDao = getIt<ExpenseCategoryDao>();
    _savingsDao = getIt<SavingsGoalDao>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final sources = await _incomeDao.getByCurrency(_currency);
    final categories = await _expenseDao.getAll();
    final goals = await _savingsDao.getAll();

    if (widget.transactionId != null) {
      final row = await _txDao.getById(widget.transactionId!);
      if (row != null) {
        final tx = TransactionMappers.toEntity(row);
        _type = tx.type;
        _currency = tx.currency;
        _amountController.text = tx.amount.toStringAsFixed(2);
        _noteController.text = tx.note ?? '';
        _date = DateTime.fromMillisecondsSinceEpoch(tx.date * 1000);
        _categoryId = tx.categoryId;
        _savingsGoalId = tx.savingsGoalId;
      }
    } else {
      if (_type == TransactionType.income && sources.isNotEmpty) {
        _categoryId = sources.first.id;
      }
      if (_type == TransactionType.expense && categories.isNotEmpty) {
        _categoryId = categories.first.id;
      }
    }

    setState(() {
      _incomeSources = sources;
      _expenseCategories = categories;
      _savingsGoals = goals;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_type == TransactionType.income && _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an income source')),
      );
      return;
    }
    if (_type == TransactionType.expense && _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expense category')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final id = widget.transactionId ?? const Uuid().v4();
      final dateSec = (_date.millisecondsSinceEpoch / 1000).round();
      final createdAt = (DateTime.now().millisecondsSinceEpoch / 1000).round();

      final tx = Transaction(
        id: id,
        type: _type,
        amount: amount,
        currency: _currency,
        date: dateSec,
        createdAt: createdAt,
        categoryId: _categoryId,
        savingsGoalId: _savingsGoalId,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      if (widget.transactionId != null) {
        await _txDao.update(TransactionInsert(
          id: tx.id,
          type: tx.type,
          amount: tx.amount,
          currency: tx.currency,
          date: tx.date,
          createdAt: tx.createdAt,
          categoryId: tx.categoryId,
          savingsGoalId: tx.savingsGoalId,
          note: tx.note,
        ));
      } else {
        await _txDao.insert(TransactionInsert(
          id: tx.id,
          type: tx.type,
          amount: tx.amount,
          currency: tx.currency,
          date: tx.date,
          createdAt: tx.createdAt,
          categoryId: tx.categoryId,
          savingsGoalId: tx.savingsGoalId,
          note: tx.note,
        ));
      }

      if (mounted) {
        context.pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transactionId != null ? 'Edit Transaction' : 'Add Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.income,
                        icon: Icon(Icons.arrow_downward),
                        label: Text('Income'),
                      ),
                      ButtonSegment(
                        value: TransactionType.expense,
                        icon: Icon(Icons.arrow_upward),
                        label: Text('Expense'),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) {
                      setState(() {
                        _type = s.first;
                        _categoryId = null;
                        _loadData();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${_currency.symbol} ',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<Currency>(
                    segments: Currency.values.map((c) {
                      return ButtonSegment(
                        value: c,
                        label: Text(c.code),
                      );
                    }).toList(),
                    selected: {_currency},
                    onSelectionChanged: (s) {
                      setState(() {
                        _currency = s.first;
                        _categoryId = null;
                        _loadData();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_type == TransactionType.income) ...[
                    DropdownButtonFormField<String>(
                      value: _categoryId,
                      decoration: const InputDecoration(labelText: 'Income Source'),
                      items: _incomeSources.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    if (_savingsGoals.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _savingsGoalId,
                        decoration: const InputDecoration(
                          labelText: 'Allocate to Savings Goal (optional)',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None'),
                          ),
                          ..._savingsGoals.map((g) {
                            return DropdownMenuItem(
                              value: g.id,
                              child: Text(g.name),
                            );
                          }),
                        ],
                        onChanged: (v) => setState(() => _savingsGoalId = v),
                      ),
                    ],
                  ],
                  if (_type == TransactionType.expense) ...[
                    DropdownButtonFormField<String>(
                      value: _categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _expenseCategories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text('Date: ${_date.day}/${_date.month}/${_date.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
    );
  }
}
