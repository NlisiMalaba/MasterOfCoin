import '../constants/category_defaults.dart';
import '../daos/expense_category_dao.dart';
import '../daos/income_source_dao.dart';
import '../daos/app_settings_dao.dart';
import 'app_database.dart';
import '../../features/expenses/domain/entity/expense_category.dart';
import '../../features/income/domain/entity/income_source.dart';
import '../../shared/domain/currency.dart';

/// Seeds the database with default data on first run.
class DatabaseSeed {
  DatabaseSeed._();

  static const String _seedKey = 'database_seeded';

  static Future<void> runIfNeeded(
    AppSettingsDao settingsDao,
    ExpenseCategoryDao categoryDao,
    IncomeSourceDao incomeSourceDao,
  ) async {
    final seeded = await settingsDao.getBool(_seedKey);
    if (seeded) return;

    final now = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    for (final cat in kDefaultExpenseCategories) {
      await categoryDao.insert(ExpenseCategory(
        id: cat.id,
        name: cat.name,
        iconName: cat.iconName,
        colorHex: cat.colorHex,
        createdAt: now,
        isSystem: true,
      ));
    }

    for (final src in kDefaultIncomeSources) {
      await incomeSourceDao.insert(IncomeSource(
        id: src.id,
        name: src.name,
        currency: Currency.fromCode(src.currency),
        createdAt: now,
      ));
    }

    await settingsDao.setBool(_seedKey, true);
  }
}
