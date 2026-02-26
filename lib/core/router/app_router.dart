import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/transactions/presentation/pages/transaction_form_page.dart';
import '../../features/transactions/presentation/pages/transactions_list_page.dart';
import '../../features/savings_goals/presentation/pages/savings_goals_list_page.dart';
import '../../features/budgets/presentation/pages/budgets_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/recurring/presentation/pages/recurring_templates_page.dart';

class AppRouter {
  AppRouter._();

  static const String dashboard = '/';
  static const String onboarding = '/onboarding';
  static const String settings = '/settings';
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String savingsGoals = '/savings-goals';
  static const String budgets = '/budgets';
  static const String analytics = '/analytics';
  static const String recurring = '/recurring';
  static String editTransaction(String id) => '/transactions/edit/$id';

  static GoRouter createRouter({
    required bool Function() isOnboardingComplete,
  }) {
    return GoRouter(
      initialLocation: dashboard,
      redirect: (context, state) {
        final isOnboarding = isOnboardingComplete();
        final isOnOnboarding = state.matchedLocation == onboarding;

        if (!isOnboarding && !isOnOnboarding) {
          return onboarding;
        }
        if (isOnboarding && isOnOnboarding) {
          return dashboard;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: dashboard,
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: onboarding,
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: settings,
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: transactions,
          builder: (context, state) => const TransactionsListPage(),
        ),
        GoRoute(
          path: addTransaction,
          builder: (context, state) => const TransactionFormPage(),
        ),
        GoRoute(
          path: '/transactions/edit/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return TransactionFormPage(transactionId: id);
          },
        ),
        GoRoute(
          path: savingsGoals,
          builder: (context, state) => const SavingsGoalsListPage(),
        ),
        GoRoute(
          path: budgets,
          builder: (context, state) => const BudgetsPage(),
        ),
        GoRoute(
          path: analytics,
          builder: (context, state) => const AnalyticsPage(),
        ),
        GoRoute(
          path: recurring,
          builder: (context, state) => const RecurringTemplatesPage(),
        ),
      ],
    );
  }
}
