# Tasks

## Task List

- [ ] 1. Add new dependencies to pubspec.yaml
  - [ ] 1.1 Add flutter_secure_storage, local_auth, flutter_local_notifications to pubspec.yaml
  - [ ] 1.2 Add crypto (or pointycastle) for PIN hashing to pubspec.yaml
  - [ ] 1.3 Run `flutter pub get` and verify no conflicts

- [ ] 2. Database migrations
  - [ ] 2.1 Add migration v3 to migrations.dart: ALTER TABLE transactions ADD COLUMN payment_method TEXT; add index idx_transactions_payment_method
  - [ ] 2.2 Bump AppDatabase version to 3 and wire v3 migration in runMigration
  - [ ] 2.3 Add migration v4 to migrations.dart: seed informal economy categories and income sources (guarded by seed_v4_done app_settings key)
  - [ ] 2.4 Bump AppDatabase version to 4 and wire v4 migration in runMigration

- [ ] 3. Update Transaction data model for payment_method
  - [ ] 3.1 Add nullable paymentMethod field to Transaction entity (lib/features/transactions/domain/entity/transaction.dart)
  - [ ] 3.2 Add nullable paymentMethod field to TransactionInsert and TransactionRow in transaction_dao.dart
  - [ ] 3.3 Update TransactionDao._toMap to include payment_method column
  - [ ] 3.4 Update TransactionMappers.rowFromMap to read payment_method from DB row
  - [ ] 3.5 Extend TransactionDao.getAll to accept optional paymentMethod and keyword (LIKE %keyword% on note) filter params

- [ ] 4. ExchangeRateDao
  - [ ] 4.1 Create lib/core/database/daos/exchange_rate_dao.dart with insert, getAll(startDate, endDate), getLatest methods
  - [ ] 4.2 Register ExchangeRateDao singleton in injection.dart

- [ ] 5. Core AuthService (PIN + Biometric)
  - [ ] 5.1 Create lib/core/auth/pin_hasher.dart: hashPin(pin) using SHA-256 + random salt stored separately in Secure_Storage; verifyPin(pin, storedHash) method
  - [ ] 5.2 Create lib/core/auth/auth_service.dart implementing isPinEnabled, setPin, verifyPin, clearPin, isBiometricEnabled, setBiometricEnabled, isBiometricAvailable, authenticateWithBiometric
  - [ ] 5.3 Register AuthService singleton in injection.dart
  - [ ] 5.4 Write unit tests for PinHasher: hash != raw pin, verify(correct) == true, verify(wrong) == false
  - [ ] 5.5 Write property tests for PIN hash round-trip (Property 1) and PIN disable clears credentials (Property 2)

- [ ] 6. Auth Gate UI
  - [ ] 6.1 Create lib/features/auth/presentation/pages/auth_gate_page.dart: PIN entry UI with 4–6 digit input, attempt counter, 30-second lockout timer display
  - [ ] 6.2 Create lib/features/auth/presentation/cubit/auth_cubit.dart: manages lock state, attempt count, lockout timer
  - [ ] 6.3 Wrap MasterOfCoinApp with AppLifecycleObserver in app.dart: on resume after >30s, push AuthGatePage as full-screen modal if lock is enabled
  - [ ] 6.4 Write unit tests for AuthCubit: 5 wrong attempts triggers lockout, correct PIN unlocks, lockout expires after 30s

- [ ] 7. PIN and Biometric Settings UI
  - [ ] 7.1 Create lib/features/auth/presentation/pages/pin_setup_page.dart: enter new PIN, confirm PIN, save via AuthService
  - [ ] 7.2 Create lib/features/auth/presentation/pages/pin_change_page.dart: verify current PIN, then enter and confirm new PIN
  - [ ] 7.3 Add Security section to SettingsPage with PIN enable/disable toggle and Biometric enable/disable toggle
  - [ ] 7.4 Add /pin-setup and /pin-change routes to AppRouter
  - [ ] 7.5 Write unit tests for PIN setup flow: enable PIN, verify stored, disable PIN, verify cleared

- [ ] 8. NotificationService
  - [ ] 8.1 Create lib/core/notifications/notification_service.dart wrapping flutter_local_notifications: initialize, requestPermission, showBudgetAlert, showRecurringApplied
  - [ ] 8.2 Initialize NotificationService in main.dart after configureDependencies
  - [ ] 8.3 Register NotificationService singleton in injection.dart
  - [ ] 8.4 Configure Android notification channel and iOS permissions in platform files (AndroidManifest.xml, AppDelegate.swift/Info.plist)
  - [ ] 8.5 Write unit tests for NotificationService: permission request, showBudgetAlert constructs correct title/body

- [ ] 9. BudgetAlertService
  - [ ] 9.1 Create lib/core/notifications/budget_alert_service.dart: checkAndAlert(transactionCategoryId, currency) method that queries BudgetAllocationDao + TransactionDao, computes utilization, fires notification if >= 80% and not already sent this month
  - [ ] 9.2 Call BudgetAlertService.checkAndAlert after every successful expense transaction save in TransactionFormPage (and any other save paths)
  - [ ] 9.3 Register BudgetAlertService in injection.dart
  - [ ] 9.4 Write unit tests for BudgetAlertService: alert fires at exactly 80%, does not fire below 80%, does not fire twice in same month
  - [ ] 9.5 Write property tests for budget alert threshold (Property 19) and deduplication (Property 20)

- [ ] 10. Transaction form: payment method and validation improvements
  - [ ] 10.1 Add PaymentMethod enum (cash, ecocash, onemoney, innbucks, bankTransfer) to lib/shared/domain/payment_method.dart
  - [ ] 10.2 Add Payment Method selector widget to TransactionFormPage (optional dropdown/chip selector)
  - [ ] 10.3 Wire paymentMethod field through TransactionFormPage save/load logic
  - [ ] 10.4 Add inline validation to TransactionFormPage: amount range (>0, <=999999999), note length (<=500 chars), required category
  - [ ] 10.5 Add error banner widget to TransactionFormPage for database save failures with retry
  - [ ] 10.6 Ensure form state is preserved on validation failure (no field reset)
  - [ ] 10.7 Write unit tests for TransactionFormValidator: zero amount, negative amount, over-max amount, valid amount, note too long, note valid
  - [ ] 10.8 Write property tests for amount validation (Property 3), non-numeric rejection (Property 4), note length (Property 5), form state preservation (Property 6)

- [ ] 11. Transaction list: payment method display and search/filter
  - [ ] 11.1 Update transaction list item widget to display Payment_Method tag when present
  - [ ] 11.2 Create lib/features/transactions/presentation/cubit/transaction_filter_cubit.dart holding TransactionFilterState (keyword, categoryId, dateRange, currency, paymentMethod)
  - [ ] 11.3 Add search bar to TransactionsListPage with 300ms debounce on keyword changes
  - [ ] 11.4 Add filter controls to TransactionsListPage: Category dropdown, Date Range picker, Currency toggle, Payment Method dropdown
  - [ ] 11.5 Wire TransactionFilterCubit to TransactionDao.getAll with combined filter params
  - [ ] 11.6 Add empty-state widget to TransactionsListPage for no-results scenario
  - [ ] 11.7 Write unit tests for TransactionFilterCubit: keyword filter, payment method filter, combined AND logic, clear restores full list
  - [ ] 11.8 Write property tests for filter AND logic (Property 17), filter clear (Property 18), payment method filter (Property 8), payment method round-trip (Property 7)

- [ ] 12. Informal economy categories seed
  - [ ] 12.1 Add informal economy income categories to category_defaults.dart: Cash Job, Market Sale, Remittance Received, Diaspora Transfer
  - [ ] 12.2 Add informal economy expense categories to category_defaults.dart: Market Purchase, Street Food, Informal Transport, Remittance Sent
  - [ ] 12.3 Extend DatabaseSeed to insert informal economy categories/sources if seed_v4_done is false, then set seed_v4_done = true
  - [ ] 12.4 Mark informal economy categories with is_system = 1 and ensure ExpenseCategoryDao.delete rejects system categories
  - [ ] 12.5 Write unit tests for seed: all 8 informal categories present after seed, system categories not deletable
  - [ ] 12.6 Write property test for system category deletion rejection (Property 9)

- [ ] 13. Exchange rate history and Volatility Dashboard
  - [ ] 13.1 Update SettingsPage exchange rate save to also call ExchangeRateDao.insert with the new rate and current timestamp
  - [ ] 13.2 Create lib/features/exchange_rate/presentation/cubit/exchange_rate_cubit.dart: loads rates from ExchangeRateDao, supports time range filter (30d, 90d, all)
  - [ ] 13.3 Create lib/features/exchange_rate/presentation/pages/volatility_dashboard_page.dart: fl_chart LineChart of rate over time, current rate header, percentage change display, time range selector, empty state
  - [ ] 13.4 Add /exchange-rate-history route to AppRouter
  - [ ] 13.5 Add "Exchange Rate History" entry to SettingsPage linking to VolatilityDashboardPage
  - [ ] 13.6 Write unit tests for ExchangeRateCubit: loads rates, filters by time range, computes percentage change, handles empty list
  - [ ] 13.7 Write property tests for exchange rate round-trip (Property 10), percentage change calculation (Property 11), time range filter (Property 12)

- [ ] 14. CSV Export
  - [ ] 14.1 Create lib/features/export/csv_exporter.dart: buildCsvString(transactions) returns CSV string with header Date,Type,Amount,Currency,Category,PaymentMethod,Note; dates as YYYY-MM-DD, amounts to 2dp
  - [ ] 14.2 Create lib/features/export/export_service.dart: exportTransactions(startDate, endDate) queries TransactionDao, calls CsvExporter, writes temp file, shares via share_plus
  - [ ] 14.3 Add CSV Export button to TransactionsListPage; show date range picker dialog on tap
  - [ ] 14.4 Write unit tests for CsvExporter: header row exact match, date format, amount format, empty result produces header-only
  - [ ] 14.5 Write property tests for CSV header correctness (Property 13), date range filter (Property 15), date/amount formatting (Property 16)

- [ ] 15. ZIMRA Tax Export
  - [ ] 15.1 Create lib/features/export/zimra_exporter.dart: buildZimraCsvString(transactions) with header Date,Type,Category,Amount,Currency,Note; rows ordered by date ascending
  - [ ] 15.2 Add exportYear(int year) to ExportService: queries TransactionDao for the full calendar year, calls ZimraExporter, shares file
  - [ ] 15.3 Add ZIMRA Export option to SettingsPage (under Data section); show year picker dialog on tap
  - [ ] 15.4 Write unit tests for ZimraExporter: header exact match, row ordering, empty year produces header-only
  - [ ] 15.5 Write property tests for ZIMRA CSV header (Property 13), row ordering and completeness (Property 14)

- [ ] 16. Auto-apply recurring templates
  - [ ] 16.1 Create lib/features/recurring/auto_apply_service.dart: isDue(template, now) logic for weekly/monthly; applyDueTemplates() queries all templates, inserts transactions for due ones, updates last_applied_date, fires notification
  - [ ] 16.2 Register a WorkManager periodic task named auto_apply_recurring (frequency: once per day) in main.dart, pointing to a top-level callback that calls AutoApplyService
  - [ ] 16.3 Implement idempotency check in AutoApplyService: before inserting, check if a transaction with same template note + today's date already exists
  - [ ] 16.4 Register AutoApplyService in injection.dart
  - [ ] 16.5 Write unit tests for AutoApplyService: weekly due after 8 days, weekly not due after 3 days, monthly due in new month, monthly not due same month, null last_applied_date is always due
  - [ ] 16.6 Write property tests for due-date logic (Property 21), correct transaction creation (Property 22), idempotence (Property 23)

- [ ] 17. Shona/Ndebele localization scaffolding
  - [ ] 17.1 Audit all user-visible string literals in screens covered by this spec and extract them to app_en.arb with appropriate keys
  - [ ] 17.2 Create lib/l10n/app_sn.arb with Shona translations for all keys in app_en.arb (use placeholder translations if professional translation unavailable)
  - [ ] 17.3 Create lib/l10n/app_nd.arb with Ndebele translations for all keys in app_en.arb
  - [ ] 17.4 Add AppSettingsDao key app_language and load/save logic in AppState
  - [ ] 17.5 Add Language selector to SettingsPage (English / Shona / Ndebele); on change, save to app_settings and call setState on root widget to update locale
  - [ ] 17.6 Update MasterOfCoinApp to read locale from AppState and pass to MaterialApp.router's locale parameter; add supportedLocales and localizationsDelegates
  - [ ] 17.7 Write unit test for ARB key completeness: parse all three ARB files, assert sn and nd key sets are supersets of en key set
  - [ ] 17.8 Write property test for language preference persistence (Property 25)

- [ ] 18. Integration and regression tests
  - [ ] 18.1 Write widget test for AuthGatePage: correct PIN unlocks, wrong PIN increments counter, 5 wrong PINs triggers lockout UI
  - [ ] 18.2 Write widget test for TransactionFormPage: payment method selector present, validation errors shown inline, form state preserved on error
  - [ ] 18.3 Write widget test for TransactionsListPage: search bar filters list, clear restores full list, empty state shown when no results
  - [ ] 18.4 Write widget test for VolatilityDashboardPage: empty state shown with <2 data points, chart rendered with >=2 points
  - [ ] 18.5 Write integration test for full transaction save flow with payment method: save → retrieve → verify payment method persisted
