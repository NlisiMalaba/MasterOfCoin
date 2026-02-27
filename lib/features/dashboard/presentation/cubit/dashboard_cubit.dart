import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/database/daos/expense_category_dao.dart';
import '../../../../core/database/daos/transaction_dao.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../shared/domain/currency.dart';
import '../../../../shared/domain/transaction_type.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(DashboardInitial()) {
    _transactionDao = getIt<TransactionDao>();
    _categoryDao = getIt<ExpenseCategoryDao>();
  }

  late final TransactionDao _transactionDao;
  late final ExpenseCategoryDao _categoryDao;

  Future<void> load() async {
    emit(DashboardLoading());
    try {
      final now = DateTime.now();
      final startOfMonth = now.startOfMonth;
      final endOfMonth = now.endOfMonth;
      final startSec = startOfMonth.toUnixSeconds;
      final endSec = endOfMonth.toUnixSeconds;

      // This month's income and expenses
      final usdIncome = await _transactionDao.sumByTypeAndCurrency(
        TransactionType.income,
        Currency.usd.code,
        startDate: startSec,
        endDate: endSec,
      );
      final usdExpenses = await _transactionDao.sumByTypeAndCurrency(
        TransactionType.expense,
        Currency.usd.code,
        startDate: startSec,
        endDate: endSec,
      );
      final zwgIncome = await _transactionDao.sumByTypeAndCurrency(
        TransactionType.income,
        Currency.zwg.code,
        startDate: startSec,
        endDate: endSec,
      );
      final zwgExpenses = await _transactionDao.sumByTypeAndCurrency(
        TransactionType.expense,
        Currency.zwg.code,
        startDate: startSec,
        endDate: endSec,
      );

      // Total balance (all-time)
      final usdIncomeTotal = await _transactionDao.sumByTypeAndCurrency(
        TransactionType.income,
        Currency.usd.code,
      );
      final usdExpensesTotal = await _transactionDao.sumByTypeAndCurrency(
        TransactionType.expense,
        Currency.usd.code,
      );
      final zwgIncomeTotal = await _transactionDao.sumByTypeAndCurrency(
        TransactionType.income,
        Currency.zwg.code,
      );
      final zwgExpensesTotal = await _transactionDao.sumByTypeAndCurrency(
        TransactionType.expense,
        Currency.zwg.code,
      );

      final usdBalance = usdIncomeTotal - usdExpensesTotal;
      final zwgBalance = zwgIncomeTotal - zwgExpensesTotal;

      // Expenses by category (this month, USD)
      final byCategoryRaw = await _transactionDao.expensesByCategory(
        currency: Currency.usd.code,
        startDate: startSec,
        endDate: endSec,
      );
      final categories = await _categoryDao.getAll();
      final categoryMap = {for (final c in categories) c.id: c.name};
      final expensesByCat = byCategoryRaw
          .map((r) => MapEntry(
                categoryMap[r['category_id'] as String?] ?? 'Other',
                (r['total'] as num).toDouble(),
              ))
          .where((e) => e.value > 0)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Monthly totals (last 6 months, USD)
      final monthlyIncomeRaw = await _transactionDao.monthlyTotals(
        type: TransactionType.income,
        currency: Currency.usd.code,
        months: 6,
      );
      final monthlyExpensesRaw = await _transactionDao.monthlyTotals(
        type: TransactionType.expense,
        currency: Currency.usd.code,
        months: 6,
      );
      final incomeByMonth = <String, double>{};
      for (final r in monthlyIncomeRaw) {
        incomeByMonth[r['month'] as String] = (r['total'] as num).toDouble();
      }
      final expensesByMonth = <String, double>{};
      for (final r in monthlyExpensesRaw) {
        expensesByMonth[r['month'] as String] = (r['total'] as num).toDouble();
      }
      final allMonths =
          {...incomeByMonth.keys, ...expensesByMonth.keys}.toList()..sort();
      final incomeList = allMonths.map((m) => incomeByMonth[m] ?? 0.0).toList();
      final expensesList =
          allMonths.map((m) => expensesByMonth[m] ?? 0.0).toList();

      emit(DashboardLoaded(
        usdBalance: usdBalance,
        zwgBalance: zwgBalance,
        usdIncome: usdIncome,
        usdExpenses: usdExpenses,
        zwgIncome: zwgIncome,
        zwgExpenses: zwgExpenses,
        expensesByCategory: expensesByCat,
        monthlyIncome: incomeList,
        monthlyExpenses: expensesList,
        monthLabels: allMonths,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
