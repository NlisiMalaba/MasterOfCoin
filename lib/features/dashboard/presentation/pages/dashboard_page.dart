import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/currency_display.dart';
import '../cubit/dashboard_cubit.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MasterOfCoin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _BalanceCard(
                    usdBalance: data.usdBalance,
                    zwgBalance: data.zwgBalance,
                  ),
                  const SizedBox(height: 16),
                  _SummaryCard(
                    usdIncome: data.usdIncome,
                    usdExpenses: data.usdExpenses,
                    zwgIncome: data.zwgIncome,
                    zwgExpenses: data.zwgExpenses,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.list),
                    title: const Text('All Transactions'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/transactions'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.savings),
                    title: const Text('Savings Goals'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/savings-goals'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: const Text('Budgets'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/budgets'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.analytics),
                    title: const Text('Analytics'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/analytics'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.repeat),
                    title: const Text('Recurring'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/recurring'),
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
        label: const Text('Add'),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.usdBalance,
    required this.zwgBalance,
  });

  final double usdBalance;
  final double zwgBalance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            CurrencyDisplay(amount: usdBalance, currency: 'USD'),
            const SizedBox(height: 4),
            CurrencyDisplay(amount: zwgBalance, currency: 'ZWG'),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Month',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Income',
                    usd: usdIncome,
                    zwg: zwgIncome,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: 'Expenses',
                    usd: usdExpenses,
                    zwg: zwgExpenses,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.usd,
    required this.zwg,
    required this.color,
  });

  final String label;
  final double usd;
  final double zwg;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        CurrencyDisplay(amount: usd, currency: 'USD', compact: true),
        CurrencyDisplay(amount: zwg, currency: 'ZWG', compact: true),
      ],
    );
  }
}
