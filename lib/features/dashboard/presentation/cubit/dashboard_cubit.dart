import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/database/daos/transaction_dao.dart';
import '../../../../core/extensions/date_time_extensions.dart';
import '../../../../shared/domain/currency.dart';
import '../../../../shared/domain/transaction_type.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(DashboardInitial()) {
    _transactionDao = getIt<TransactionDao>();
  }

  late final TransactionDao _transactionDao;

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

      emit(DashboardLoaded(
        usdBalance: usdBalance,
        zwgBalance: zwgBalance,
        usdIncome: usdIncome,
        usdExpenses: usdExpenses,
        zwgIncome: zwgIncome,
        zwgExpenses: zwgExpenses,
      ));
    } catch (e, st) {
      emit(DashboardError(e.toString()));
    }
  }
}
