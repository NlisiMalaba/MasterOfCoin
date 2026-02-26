import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/database/daos/transaction_dao.dart';
import '../../../../core/database/daos/expense_category_dao.dart';
import '../../../../core/database/daos/savings_goal_dao.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/domain/currency.dart';
import '../../../../shared/domain/transaction_type.dart';
import '../../../expenses/domain/entity/expense_category.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late TransactionDao _txDao;
  late ExpenseCategoryDao _categoryDao;
  late SavingsGoalDao _savingsDao;

  Currency _currency = Currency.usd;
  DateTime _selectedMonth = DateTime.now();
  bool _loading = true;

  double _income = 0;
  double _expenses = 0;
  List<MapEntry<String, double>> _expensesByCategory = [];
  List<double> _monthlyIncome = [];
  List<double> _monthlyExpenses = [];
  List<String> _monthLabels = [];

  @override
  void initState() {
    super.initState();
    _txDao = getIt<TransactionDao>();
    _categoryDao = getIt<ExpenseCategoryDao>();
    _savingsDao = getIt<SavingsGoalDao>();
    _load();
  }

  int _startOfMonth() {
    return DateTime(_selectedMonth.year, _selectedMonth.month, 1).millisecondsSinceEpoch ~/ 1000;
  }

  int _endOfMonth() {
    return DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59)
        .millisecondsSinceEpoch ~/ 1000;
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final start = _startOfMonth();
    final end = _endOfMonth();

    final income = await _txDao.sumByTypeAndCurrency(
      TransactionType.income,
      _currency.code,
      startDate: start,
      endDate: end,
    );
    final expenses = await _txDao.sumByTypeAndCurrency(
      TransactionType.expense,
      _currency.code,
      startDate: start,
      endDate: end,
    );

    final byCategory = await _txDao.expensesByCategory(
      currency: _currency.code,
      startDate: start,
      endDate: end,
    );

    final categories = await _categoryDao.getAll();
    final categoryMap = {for (final c in categories) c.id: c.name};
    final expensesByCat = byCategory
        .map((r) => MapEntry(
              categoryMap[r['category_id'] as String?] ?? 'Other',
              (r['total'] as num).toDouble(),
            ))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final monthlyIncome = await _txDao.monthlyTotals(
      type: TransactionType.income,
      currency: _currency.code,
      months: 6,
    );
    final monthlyExpenses = await _txDao.monthlyTotals(
      type: TransactionType.expense,
      currency: _currency.code,
      months: 6,
    );

    final incomeByMonth = <String, double>{};
    for (final r in monthlyIncome) {
      incomeByMonth[r['month'] as String] = (r['total'] as num).toDouble();
    }
    final expensesByMonth = <String, double>{};
    for (final r in monthlyExpenses) {
      expensesByMonth[r['month'] as String] = (r['total'] as num).toDouble();
    }

    final allMonths = {...incomeByMonth.keys, ...expensesByMonth.keys}.toList()..sort();
    final incomeList = allMonths.map((m) => incomeByMonth[m] ?? 0.0).toList();
    final expensesList = allMonths.map((m) => expensesByMonth[m] ?? 0.0).toList();

    setState(() {
      _income = income;
      _expenses = expenses;
      _expensesByCategory = expensesByCat;
      _monthlyIncome = incomeList;
      _monthlyExpenses = expensesList;
      _monthLabels = allMonths;
      _loading = false;
    });
  }

  static const _chartColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFFF9800),
    Color(0xFF00BCD4),
    Color(0xFFE91E63),
    Color(0xFFF44336),
    Color(0xFF673AB7),
    Color(0xFF795548),
    Color(0xFF607D8B),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final pick = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (pick != null) {
                setState(() => _selectedMonth = pick);
                _load();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: () {
              setState(() {
                _currency = _currency == Currency.usd ? Currency.zwg : Currency.usd;
                _load();
              });
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${_selectedMonth.month}/${_selectedMonth.year} • ${_currency.code}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _SummaryChip(
                                  label: 'Income',
                                  amount: _income,
                                  currency: _currency,
                                  color: Colors.green,
                                ),
                                _SummaryChip(
                                  label: 'Expenses',
                                  amount: _expenses,
                                  currency: _currency,
                                  color: Colors.red,
                                ),
                                _SummaryChip(
                                  label: 'Balance',
                                  amount: _income - _expenses,
                                  currency: _currency,
                                  color: (_income - _expenses) >= 0 ? Colors.green : Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_expensesByCategory.isNotEmpty) ...[
                      Text('Spending by Category',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _expensesByCategory.asMap().entries.map((e) {
                              final i = e.key % _chartColors.length;
                              return PieChartSectionData(
                                value: e.value.value,
                                title: '',
                                color: _chartColors[i],
                                radius: 60,
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._expensesByCategory.asMap().entries.map((e) {
                        final i = e.key % _chartColors.length;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: _chartColors[i],
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e.value.key)),
                              Text(CurrencyFormatter.format(e.value.value, _currency)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (_monthLabels.isNotEmpty) ...[
                      Text('Income vs Expenses (6 months)',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: ([
                              ..._monthlyIncome,
                              ..._monthlyExpenses,
                            ].fold<double>(0, (a, b) => a > b ? a : b) * 1.2)
                                .clamp(10.0, double.infinity),
                            barGroups: [
                              for (var i = 0; i < _monthLabels.length; i++)
                                BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: _monthlyIncome[i],
                                      color: Colors.green,
                                      width: 8,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                    BarChartRodData(
                                      toY: _monthlyExpenses[i],
                                      color: Colors.red,
                                      width: 8,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ],
                                  showingTooltipIndicators: [0, 1],
                                ),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, meta) {
                                    final i = v.toInt();
                                    if (i >= 0 && i < _monthLabels.length) {
                                      final m = _monthLabels[i];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          m.length >= 7 ? m.substring(2) : m,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                  reservedSize: 28,
                                  interval: 1,
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                          swapAnimationDuration: const Duration(milliseconds: 300),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  final String label;
  final double amount;
  final Currency currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatCompact(amount, currency),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
