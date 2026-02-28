import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

import '../backup/backup_restore_service.dart';
import '../database/app_database.dart';
import '../database/daos/transaction_dao.dart';
import '../database/daos/income_source_dao.dart';
import '../database/daos/expense_category_dao.dart';
import '../database/daos/savings_goal_dao.dart';
import '../database/daos/savings_usage_dao.dart';
import '../database/daos/budget_allocation_dao.dart';
import '../database/daos/app_settings_dao.dart';
import '../database/daos/recurring_template_dao.dart';
import '../theme/theme_controller.dart';
import '../database/seed.dart';
import '../../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../../features/transactions/domain/repositories/transaction_repository.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final appDocDir = await getApplicationDocumentsDirectory();
  await AppDatabase.instance.init(appDocDir.path);

  getIt.registerSingleton<AppDatabase>(AppDatabase.instance);
  getIt.registerSingleton<BackupRestoreService>(
    BackupRestoreService(database: getIt<AppDatabase>()),
  );
  getIt.registerSingleton<TransactionDao>(TransactionDao(AppDatabase.instance));
  getIt.registerSingleton<IncomeSourceDao>(IncomeSourceDao(AppDatabase.instance));
  getIt.registerSingleton<ExpenseCategoryDao>(ExpenseCategoryDao(AppDatabase.instance));
  getIt.registerSingleton<BudgetAllocationDao>(BudgetAllocationDao(AppDatabase.instance));
  getIt.registerSingleton<AppSettingsDao>(AppSettingsDao(AppDatabase.instance));
  getIt.registerSingleton<ThemeController>(
    ThemeController(getIt<AppSettingsDao>()),
  );
  getIt.registerSingleton<RecurringTemplateDao>(RecurringTemplateDao(AppDatabase.instance));
  getIt.registerSingleton<SavingsUsageDao>(SavingsUsageDao(AppDatabase.instance));
  getIt.registerSingleton<SavingsGoalDao>(
    SavingsGoalDao(
      AppDatabase.instance,
      getIt<TransactionDao>(),
      getIt<SavingsUsageDao>(),
    ),
  );

  getIt.registerSingleton<TransactionRepository>(
    TransactionRepositoryImpl(getIt<TransactionDao>()),
  );

  await DatabaseSeed.runIfNeeded(
    getIt<AppSettingsDao>(),
    getIt<ExpenseCategoryDao>(),
    getIt<IncomeSourceDao>(),
  );
}
