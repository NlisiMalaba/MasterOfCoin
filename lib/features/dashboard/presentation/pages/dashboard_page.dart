import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/currency_display.dart';
import '../../../../shared/domain/currency.dart';
import '../../../../core/widgets/stat_card.dart';
import '../cubit/dashboard_cubit.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => DashboardCubit()..load(),
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DashboardError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            final data = state is DashboardLoaded ? state : null;
            if (data == null) return const SizedBox.shrink();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardCubit>().load();
              },
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 0,
                    floating: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    title: const Text('MasterOfCoin'),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          Text(
                            'Welcome back',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 24),
                          _BalanceSection(
                            usdBalance: data.usdBalance,
                            zwgBalance: data.zwgBalance,
                          ),
                          const SizedBox(height: 20),
                          _MonthlySummary(
                            usdIncome: data.usdIncome,
                            usdExpenses: data.usdExpenses,
                            zwgIncome: data.zwgIncome,
                            zwgExpenses: data.zwgExpenses,
                          ),
                          const SizedBox(height: 24),
                          _SpendingByCategory(data: data),
                          const SizedBox(height: 24),
                          _IncomeVsExpensesChart(data: data),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BalanceSection extends StatelessWidget {
  const _BalanceSection({
    required this.usdBalance,
    required this.zwgBalance,
  });

  final double usdBalance;
  final double zwgBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? const [
                  Color(0xFF1E4A4C),
                  Color(0xFF2D6F73),
                ]
              : [
                  Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          CurrencyDisplay(
            amount: usdBalance,
            currency: 'USD',
          ),
          const SizedBox(height: 4),
          Text(
            '${CurrencyFormatter.format(zwgBalance, Currency.zwg)} (ZWG)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  const _MonthlySummary({
    required this.usdIncome,
    required this.usdExpenses,
    required this.zwgIncome,
    required this.zwgExpenses,
  });

  final double usdIncome;
  final double usdExpenses;
  final double zwgIncome;
  final double zwgExpenses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This month',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Income',
                amount: '\$${usdIncome.toStringAsFixed(2)}',
                isPositive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Expenses',
                amount: '\$${usdExpenses.toStringAsFixed(2)}',
                isPositive: false,
              ),
            ),
          ],
        ),
        if (zwgIncome > 0 || zwgExpenses > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Income (ZWG)',
                  amount: 'Z\$${zwgIncome.toStringAsFixed(2)}',
                  isPositive: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Expenses (ZWG)',
                  amount: 'Z\$${zwgExpenses.toStringAsFixed(2)}',
                  isPositive: false,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SpendingByCategory extends StatelessWidget {
  const _SpendingByCategory({required this.data});

  final DashboardLoaded data;

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
    if (data.expensesByCategory.isEmpty) {
      return _AnalyticsCard(
        title: 'Spending by category',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No expenses this month',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      );
    }

    return _AnalyticsCard(
      title: 'Spending by category',
      onSeeAll: () => context.go('/analytics'),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: data.expensesByCategory.asMap().entries.map((e) {
                  final i = e.key % _chartColors.length;
                  return PieChartSectionData(
                    value: e.value.value,
                    title: '',
                    color: _chartColors[i],
                    radius: 56,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 36,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...data.expensesByCategory.asMap().entries.take(5).map((e) {
            final i = e.key % _chartColors.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _chartColors[i],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.value.key,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(e.value.value, Currency.usd),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _IncomeVsExpensesChart extends StatelessWidget {
  const _IncomeVsExpensesChart({required this.data});

  final DashboardLoaded data;

  @override
  Widget build(BuildContext context) {
    final positiveColor = AppTheme.positiveColor(context);
    final negativeColor = AppTheme.negativeColor(context);

    if (data.monthLabels.isEmpty) {
      return _AnalyticsCard(
        title: 'Income vs expenses (6 months)',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No data yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      );
    }

    final maxY = ([
      ...data.monthlyIncome,
      ...data.monthlyExpenses,
    ].fold<double>(0, (a, b) => a > b ? a : b) * 1.2).clamp(10.0, double.infinity);

    return _AnalyticsCard(
      title: 'Income vs expenses (6 months)',
      onSeeAll: () => context.go('/analytics'),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barGroups: [
              for (var i = 0; i < data.monthLabels.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data.monthlyIncome[i],
                      color: positiveColor,
                      width: 10,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    BarChartRodData(
                      toY: data.monthlyExpenses[i],
                      color: negativeColor,
                      width: 10,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
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
                    if (i >= 0 && i < data.monthLabels.length) {
                      final m = data.monthLabels[i];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          m.length >= 7 ? m.substring(2) : m,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 28,
                  interval: 1,
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
          duration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.title,
    required this.child,
    this.onSeeAll,
  });

  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.06,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'See details',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
