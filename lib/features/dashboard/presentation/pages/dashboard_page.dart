import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/currency_display.dart';
import '../../../../shared/domain/currency.dart';
import '../../../../core/widgets/nav_card.dart';
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
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => context.push('/settings'),
                      ),
                    ],
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
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                          _SectionHeader(
                            title: 'Quick actions',
                            onSeeAll: null,
                          ),
                          const SizedBox(height: 12),
                          _NavGrid(
                            onTransactions: () => context.push('/transactions'),
                            onSavings: () => context.push('/savings-goals'),
                            onBudgets: () => context.push('/budgets'),
                            onAnalytics: () => context.push('/analytics'),
                            onRecurring: () => context.push('/recurring'),
                          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add transaction'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See all',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
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
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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

class _NavGrid extends StatelessWidget {
  const _NavGrid({
    required this.onTransactions,
    required this.onSavings,
    required this.onBudgets,
    required this.onAnalytics,
    required this.onRecurring,
  });

  final VoidCallback onTransactions;
  final VoidCallback onSavings;
  final VoidCallback onBudgets;
  final VoidCallback onAnalytics;
  final VoidCallback onRecurring;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NavCard(
          icon: Icons.receipt_long,
          label: 'All Transactions',
          onTap: onTransactions,
        ),
        const SizedBox(height: 10),
        NavCard(
          icon: Icons.savings,
          label: 'Savings Goals',
          onTap: onSavings,
        ),
        const SizedBox(height: 10),
        NavCard(
          icon: Icons.account_balance_wallet,
          label: 'Budgets',
          onTap: onBudgets,
        ),
        const SizedBox(height: 10),
        NavCard(
          icon: Icons.analytics,
          label: 'Analytics',
          onTap: onAnalytics,
        ),
        const SizedBox(height: 10),
        NavCard(
          icon: Icons.repeat,
          label: 'Recurring',
          onTap: onRecurring,
        ),
      ],
    );
  }
}
