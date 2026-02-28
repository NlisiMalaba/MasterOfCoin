import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/database/daos/transaction_dao.dart'
    show TransactionDao, TransactionInsert;
import '../../../../core/database/daos/income_source_dao.dart';
import '../../../../core/database/daos/expense_category_dao.dart';
import '../../../../core/database/daos/savings_goal_dao.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../core/utils/transaction_mappers.dart';
import '../../../../shared/domain/currency.dart';
import '../../../../shared/domain/transaction_type.dart';
import '../../domain/entity/transaction.dart';

class TransactionFormPage extends StatefulWidget {
  const TransactionFormPage({
    super.key,
    this.transactionId,
    this.savingsGoalIdForTopUp,
  });

  final String? transactionId;
  /// When set, opens as income form pre-selected for this savings goal (Top up).
  final String? savingsGoalIdForTopUp;

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
  final _noteFocusNode = FocusNode();
  DateTime _date = DateTime.now();
  String? _categoryId;
  String? _savingsGoalId;

  List<dynamic> _incomeSources = [];
  List<dynamic> _expenseCategories = [];
  List<dynamic> _savingsGoals = [];
  bool _loading = false;
  bool _saving = false;
  bool _notesExpanded = false;

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

    if (widget.transactionId != null) {
      final row = await _txDao.getById(widget.transactionId!);
      if (row != null) {
        final tx = TransactionMappers.toEntity(row);
        _type = tx.type;
        _currency = tx.currency;
        _amountController.text = tx.amount.toStringAsFixed(2);
        _noteController.text = tx.note ?? '';
        _notesExpanded = (tx.note ?? '').trim().isNotEmpty;
        _date = DateTime.fromMillisecondsSinceEpoch(tx.date * 1000);
        _categoryId = tx.categoryId;
        _savingsGoalId = tx.savingsGoalId;
      }
    } else if (widget.savingsGoalIdForTopUp != null) {
      final goal = await _savingsDao.getById(widget.savingsGoalIdForTopUp!);
      if (goal != null) {
        _type = TransactionType.income;
        _currency = goal.currency;
        _savingsGoalId = goal.id;
      }
    }

    final sources = await _incomeDao.getByCurrency(_currency);
    final categories = await _expenseDao.getAll();
    final goals = await _savingsDao.getAll();

    if (widget.transactionId == null && widget.savingsGoalIdForTopUp == null) {
      if (_type == TransactionType.income && sources.isNotEmpty) {
        _categoryId = sources.first.id;
      }
      if (_type == TransactionType.expense && categories.isNotEmpty) {
        _categoryId = categories.first.id;
      }
    } else if (widget.savingsGoalIdForTopUp != null && sources.isNotEmpty) {
      _categoryId = sources.first.id;
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
    _noteFocusNode.dispose();
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
        title: Text(
          widget.transactionId != null ? 'Edit Transaction' : 'Add Transaction',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: const [ThemeToggleButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionLabel(label: 'Type'),
                          const SizedBox(height: 8),
                          _TypeSelector(
                            value: _type,
                            onChanged: (t) {
                              setState(() {
                                _type = t;
                                _categoryId = null;
                                _loadData();
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          _SectionLabel(label: 'Amount'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              prefixText: '${_currency.symbol} ',
                              prefixStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionLabel(label: 'Currency'),
                          const SizedBox(height: 8),
                          _CurrencySelector(
                            value: _currency,
                            onChanged: (c) {
                              setState(() {
                                _currency = c;
                                _categoryId = null;
                                _loadData();
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          if (_type == TransactionType.income) ...[
                            _SectionLabel(label: 'Income Source'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _categoryId,
                              decoration: const InputDecoration(
                                hintText: 'Select source',
                              ),
                              items: _incomeSources.map<DropdownMenuItem<String>>((s) {
                                return DropdownMenuItem<String>(
                                  value: s.id,
                                  child: Text(s.name),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _categoryId = v),
                            ),
                            if (_savingsGoals.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _SectionLabel(
                                label: 'Allocate to Savings Goal',
                                optional: true,
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String?>(
                                value: _savingsGoalId,
                                decoration: const InputDecoration(
                                  hintText: 'None',
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('None'),
                                  ),
                                  ..._savingsGoals.map<DropdownMenuItem<String?>>((g) {
                                    return DropdownMenuItem<String?>(
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
                            _SectionLabel(label: 'Category'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _categoryId,
                              decoration: const InputDecoration(
                                hintText: 'Select category',
                              ),
                              items: _expenseCategories.map<DropdownMenuItem<String>>((c) {
                                return DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(c.name),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _categoryId = v),
                            ),
                          ],
                          const SizedBox(height: 24),
                          _SectionLabel(label: 'Date'),
                          const SizedBox(height: 8),
                          _DateTile(
                            date: _date,
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
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _CollapsibleNoteField(
                      controller: _noteController,
                      focusNode: _noteFocusNode,
                      expanded: _notesExpanded,
                      onExpandChanged: (v) =>
                          setState(() => _notesExpanded = v),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.optional = false});

  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Text(
      optional ? '$label (optional)' : label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.value,
    required this.onChanged,
  });

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SelectorCard(
            selected: value == TransactionType.income,
            icon: Icons.south_west,
            label: 'Income',
            accentColor: const Color(0xFF2E7D32),
            onTap: () => onChanged(TransactionType.income),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SelectorCard(
            selected: value == TransactionType.expense,
            icon: Icons.north_east,
            label: 'Expense',
            accentColor: const Color(0xFFC62828),
            onTap: () => onChanged(TransactionType.expense),
          ),
        ),
      ],
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  const _CurrencySelector({
    required this.value,
    required this.onChanged,
  });

  final Currency value;
  final ValueChanged<Currency> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SelectorCard(
            selected: value == Currency.usd,
            label: 'USD',
            compact: true,
            onTap: () => onChanged(Currency.usd),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SelectorCard(
            selected: value == Currency.zwg,
            label: 'ZWG',
            compact: true,
            onTap: () => onChanged(Currency.zwg),
          ),
        ),
      ],
    );
  }
}

class _SelectorCard extends StatelessWidget {
  const _SelectorCard({
    required this.selected,
    required this.label,
    required this.onTap,
    this.icon,
    this.accentColor,
    this.compact = false,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final color = accentColor ?? primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            vertical: compact ? 14 : 18,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            color: selected ? color : surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? color
                  : onSurfaceVariant.withValues(alpha: 0.4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: compact ? 20 : 28,
                  color: selected ? Colors.white : color,
                ),
                SizedBox(height: compact ? 4 : 8),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollapsibleNoteField extends StatelessWidget {
  const _CollapsibleNoteField({
    required this.controller,
    required this.focusNode,
    required this.expanded,
    required this.onExpandChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool expanded;
  final ValueChanged<bool> onExpandChanged;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              onExpandChanged(true);
              focusNode.requestFocus();
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 22,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasText
                          ? _truncate(controller.text, 40)
                          : 'Add a note (optional)',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: hasText
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Add a note...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => focusNode.unfocus(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      focusNode.unfocus();
                      onExpandChanged(false);
                    },
                    icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                    label: const Text('Collapse'),
                  ),
                ),
              ],
            ),
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  String _truncate(String text, int maxLen) {
    final t = text.trim();
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen)}...';
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted = '${date.day}/${date.month}/${date.year}';
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 22,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                formatted,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
