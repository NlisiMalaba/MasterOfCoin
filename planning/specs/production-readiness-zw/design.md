# Design Document: Production Readiness ZW

## Overview

This document describes the technical design for making MasterOfCoin production-ready for Zimbabwean users. The scope covers 11 features: PIN/biometric app lock, robust input validation, local payment method tagging, informal economy categories, ZWG exchange rate history and volatility dashboard, ZIMRA-compatible tax export, CSV export, transaction search and filter, budget alerts, auto-apply recurring templates, and Shona/Ndebele localization scaffolding.

The app is offline-first, built with Flutter, SQLite (sqflite), BLoC/Cubit state management, GetIt DI, and go_router. All new features follow these same patterns.

---

## Architecture

The app follows a layered feature-first architecture:

```
lib/
  core/
    auth/           ← NEW: AuthService, PinHasher
    notifications/  ← NEW: NotificationService
    database/
      daos/         ← extended with ExchangeRateDao, search params
      migrations.dart ← v3, v4 migrations
  features/
    auth/           ← NEW: Auth gate, PIN setup/change screens
    exchange_rate/  ← NEW: VolatilityDashboard, ExchangeRateCubit
    export/         ← NEW: CsvExporter, ZimraExporter, ExportPage
    transactions/   ← extended: search/filter cubit, payment method UI
    settings/       ← extended: language picker, lock settings, export entry points
    recurring/      ← extended: auto-apply WorkManager callback
  l10n/
    app_en.arb      ← extended
    app_sn.arb      ← NEW (Shona)
    app_nd.arb      ← NEW (Ndebele)
```

### Dependency additions (pubspec.yaml)

| Package | Purpose |
|---|---|
| `flutter_secure_storage` | PIN hash + lock prefs storage |
| `local_auth` | Biometric authentication |
| `flutter_local_notifications` | Budget alerts, recurring apply notifications |
| `crypto` | SHA-256 + bcrypt-style PIN hashing (dart:crypto + pointycastle) |

---

## Components and Interfaces

### 1. AuthService (`lib/core/auth/auth_service.dart`)

```dart
abstract class AuthService {
  Future<bool> isPinEnabled();
  Future<void> setPin(String pin);
  Future<bool> verifyPin(String pin);
  Future<void> clearPin();
  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool enabled);
  Future<bool> isBiometricAvailable();
  Future<bool> authenticateWithBiometric();
}
```

Implementation uses `flutter_secure_storage` for PIN hash storage and `local_auth` for biometric. PIN is hashed with SHA-256 + a stored salt (never stored raw).

### 2. AuthGate (`lib/features/auth/presentation/`)

A `LifecycleObserver` wraps the root `MaterialApp.router`. On `AppLifecycleState.resumed`, if more than 30 seconds have elapsed since the app was backgrounded, the Auth Gate is pushed as a full-screen modal route. The gate is dismissed only on successful PIN or biometric authentication.

### 3. NotificationService (`lib/core/notifications/notification_service.dart`)

```dart
abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> showBudgetAlert({required String categoryName, required int percentUsed});
  Future<void> showRecurringApplied({required int count});
}
```

Wraps `flutter_local_notifications`. Notification IDs are deterministic: budget alerts use `categoryId.hashCode`, recurring summary uses a fixed ID.

### 4. ExchangeRateDao (`lib/core/database/daos/exchange_rate_dao.dart`)

```dart
class ExchangeRateDao {
  Future<void> insert(ExchangeRateRow row);
  Future<List<ExchangeRateRow>> getAll({int? startDate, int? endDate});
  Future<ExchangeRateRow?> getLatest();
}
```

### 5. CsvExporter (`lib/features/export/csv_exporter.dart`)

```dart
class CsvExporter {
  Future<void> exportTransactions({
    required DateTime startDate,
    required DateTime endDate,
  });
}
```

Queries `TransactionDao.getAll` with date range, formats rows, writes to a temp file, shares via `share_plus`.

### 6. ZimraExporter (`lib/features/export/zimra_exporter.dart`)

```dart
class ZimraExporter {
  Future<void> exportYear(int year);
}
```

Same mechanism as CsvExporter but filters by calendar year and uses ZIMRA column format.

### 7. TransactionSearchCubit (`lib/features/transactions/presentation/cubit/`)

Holds `TransactionFilterState` (keyword, categoryId, dateRange, currency, paymentMethod). Debounces keyword changes by 300ms. Calls `TransactionDao.getAll` with combined filter params.

### 8. BudgetAlertService (`lib/core/notifications/budget_alert_service.dart`)

Called after every expense transaction save. Checks `BudgetAllocationDao` for the category + current month. If spending ≥ 80% of budget and no alert has been sent this month (tracked in `app_settings`), fires a notification.

### 9. AutoApplyService (`lib/features/recurring/auto_apply_service.dart`)

WorkManager callback. Queries all `RecurringTemplateRow`s, evaluates due status, inserts transactions, updates `last_applied_date`. Idempotency key: checks if a transaction with the same template note + date already exists before inserting.

---

## Data Models

### Migration v3: `payment_method` on transactions

```sql
ALTER TABLE transactions ADD COLUMN payment_method TEXT;
CREATE INDEX idx_transactions_payment_method ON transactions(payment_method);
```

`payment_method` values: `'cash'`, `'ecocash'`, `'onemoney'`, `'innbucks'`, `'bank_transfer'`, or NULL.

### Migration v4: informal economy seed categories

No schema change. The `DatabaseSeed` class is extended to insert the informal economy categories and income sources if they don't already exist. Guarded by a `app_settings` key `seed_v4_done`.

### Updated `Transaction` entity

```dart
class Transaction extends Equatable {
  // existing fields ...
  final String? paymentMethod; // NEW
}
```

### Updated `TransactionInsert` / `TransactionRow`

Both gain a nullable `paymentMethod` field. `TransactionDao._toMap` and `TransactionMappers.rowFromMap` are updated accordingly.

### `ExchangeRateRow`

```dart
class ExchangeRateRow {
  final String id;
  final double rate;
  final int date;       // unix seconds
  final int createdAt;  // unix seconds
}
```

The `exchange_rates` table already exists in v1 schema. No migration needed for the table itself.

### `TransactionFilterParams`

```dart
class TransactionFilterParams {
  final String? keyword;
  final String? categoryId;
  final int? startDate;
  final int? endDate;
  final String? currency;
  final String? paymentMethod;
}
```

`TransactionDao.getAll` is extended to accept `keyword` (LIKE `%keyword%` on `note`) and `paymentMethod`.

### App Settings Keys (new)

| Key | Type | Purpose |
|---|---|---|
| `pin_enabled` | bool | PIN lock on/off |
| `biometric_enabled` | bool | Biometric lock on/off |
| `app_language` | String | Locale code: `en`, `sn`, `nd` |
| `budget_alert_sent_{categoryId}_{yearMonth}` | bool | Dedup budget alerts |
| `seed_v4_done` | bool | Informal economy seed guard |

---

## Correctness Properties


*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: PIN hash round-trip

*For any* valid PIN string (4–6 digits), hashing it and then verifying the original PIN against the hash must return true, verifying a different string must return false, and the stored hash must not equal the raw PIN.

**Validates: Requirements 1.2, 1.4**

### Property 2: PIN disable clears credentials

*For any* PIN that has been set and enabled, after calling `clearPin()`, `isPinEnabled()` must return false and `verifyPin` must return false for any input.

**Validates: Requirements 1.9**

### Property 3: Amount validation rejects out-of-range values

*For any* amount value that is zero, negative, or greater than 999,999,999, the transaction form validator must return a non-null error string; for any positive amount ≤ 999,999,999, the validator must return null.

**Validates: Requirements 2.1, 2.2**

### Property 4: Amount field rejects non-numeric input

*For any* string that contains characters other than digits and at most one decimal point, the amount input formatter must strip or reject those characters such that the resulting string is a valid decimal representation.

**Validates: Requirements 2.4**

### Property 5: Note length validation

*For any* note string with length > 500, the note validator must return a non-null error; for any note string with length ≤ 500, the validator must return null.

**Validates: Requirements 2.5**

### Property 6: Form state preserved on validation failure

*For any* form state (amount, note, category, date, paymentMethod), after a failed validation attempt, all field values must remain identical to their pre-validation values.

**Validates: Requirements 2.7**

### Property 7: Payment method round-trip

*For any* payment method value (including null), saving a transaction with that payment method and then retrieving it by ID must return a transaction with the identical payment method value.

**Validates: Requirements 3.2, 3.5**

### Property 8: Payment method filter correctness

*For any* payment method filter value, all transactions returned by `TransactionDao.getAll(paymentMethod: filter)` must have `payment_method == filter`.

**Validates: Requirements 3.4**

### Property 9: System categories are not deletable

*For any* expense category with `is_system == 1`, attempting to delete it must be rejected (return an error or no-op), and the category must still exist in the database afterward.

**Validates: Requirements 4.5**

### Property 10: Exchange rate save round-trip

*For any* positive rate value, after calling `ExchangeRateDao.insert`, `ExchangeRateDao.getLatest()` must return a record with that rate value (assuming it is the most recent).

**Validates: Requirements 5.1, 5.7**

### Property 11: Exchange rate percentage change calculation

*For any* list of two or more exchange rate records ordered by date, the computed percentage change must equal `(newest.rate - oldest.rate) / oldest.rate * 100`, rounded to two decimal places.

**Validates: Requirements 5.6**

### Property 12: Exchange rate time range filter

*For any* time range filter (startDate, endDate), all records returned by `ExchangeRateDao.getAll(startDate, endDate)` must have `date >= startDate AND date <= endDate`.

**Validates: Requirements 5.8**

### Property 13: CSV header correctness

*For any* export invocation (both CSV and ZIMRA), the first line of the generated CSV string must exactly match the required header for that export type.

**Validates: Requirements 6.6, 7.4**

### Property 14: ZIMRA export row ordering and completeness

*For any* set of transactions in a given year, the ZIMRA CSV must contain exactly one data row per transaction, and the rows must be ordered by date ascending.

**Validates: Requirements 6.4**

### Property 15: CSV date range filter correctness

*For any* date range (startDate, endDate), all data rows in the generated CSV must have dates within [startDate, endDate] inclusive.

**Validates: Requirements 7.3**

### Property 16: CSV date and amount formatting

*For any* transaction, the CSV formatter must produce a date string matching `YYYY-MM-DD` and an amount string with exactly 2 decimal places.

**Validates: Requirements 7.7**

### Property 17: Transaction filter AND logic

*For any* combination of active filters (keyword, categoryId, currency, paymentMethod, dateRange), every transaction returned by the search query must satisfy all active filter conditions simultaneously.

**Validates: Requirements 8.2, 8.4**

### Property 18: Filter clear restores full list

*For any* filter state, after clearing all filters and the search keyword, the returned transaction list must equal the result of an unfiltered query.

**Validates: Requirements 8.5**

### Property 19: Budget alert threshold

*For any* expense category with a budget allocation, the alert service must fire a notification if and only if `totalSpentThisMonth / budgetAmount >= 0.8`.

**Validates: Requirements 9.2**

### Property 20: Budget alert deduplication

*For any* category and calendar month, no matter how many expense transactions are saved that cross the 80% threshold, at most one budget alert notification must be sent for that category in that month.

**Validates: Requirements 9.4**

### Property 21: Recurring template due-date logic

*For any* recurring template with a given recurrence type and last_applied_date, `isDue(template, currentDate)` must return true if and only if: (weekly AND (lastApplied is null OR currentDate - lastApplied > 7 days)) OR (monthly AND (lastApplied is null OR lastApplied is in a previous calendar month)).

**Validates: Requirements 10.2, 10.3, 10.4**

### Property 22: Auto-apply creates correct transactions

*For any* due recurring template, after running `AutoApplyService`, a transaction must exist with type, amount, currency, category_id, and note matching the template, and the template's `last_applied_date` must equal the current date.

**Validates: Requirements 10.5, 10.6**

### Property 23: Auto-apply idempotence

*For any* set of recurring templates, running `AutoApplyService` twice on the same calendar day must produce the same number of new transactions as running it once (no duplicates on the second run).

**Validates: Requirements 10.8**

### Property 24: ARB key completeness

*For any* string key present in `app_en.arb`, the same key must also be present in `app_sn.arb` and `app_nd.arb`.

**Validates: Requirements 11.2**

### Property 25: Language preference persistence

*For any* locale code (`en`, `sn`, `nd`), after saving it to `app_settings` and reloading the settings, the retrieved locale code must equal the saved value.

**Validates: Requirements 11.5**

---

## Error Handling

| Scenario | Handling |
|---|---|
| Database write failure on transaction save | Show dismissible error banner with retry; preserve form state |
| PIN verification with no stored hash | Treat as no PIN set; disable auth gate |
| Biometric API unavailable | Fall back to PIN entry; show informational message |
| CSV/ZIMRA export with empty result set | Generate header-only CSV; show snackbar |
| WorkManager task fails | Log error; task will retry on next scheduled run |
| Exchange rate DAO returns empty list | Volatility dashboard shows empty state |
| Notification permission denied | Silently skip notification; do not crash |
| Invalid locale code in app_settings | Default to English |

---

## Testing Strategy

### Dual Testing Approach

Both unit tests and property-based tests are required. Unit tests cover specific examples, integration points, and edge cases. Property tests verify universal correctness across randomized inputs.

### Property-Based Testing Library

Use `dart_test` with the `fast_check` package (or `propcheck` for Dart). Each property test runs a minimum of 100 iterations.

Tag format for each property test:
`// Feature: production-readiness-zw, Property N: <property_text>`

### Unit Test Coverage

- `AuthService`: PIN set/verify/clear, biometric enable/disable
- `BudgetAlertService`: threshold calculation, dedup logic
- `AutoApplyService`: due-date logic, idempotency
- `CsvExporter`: header row, date formatting, amount formatting
- `ZimraExporter`: header row, row ordering, empty year
- `TransactionDao.getAll`: keyword filter, payment method filter, combined filters
- `ExchangeRateDao`: insert, getLatest, getAll with date range
- `TransactionFormValidator`: amount range, note length, non-numeric rejection
- ARB key completeness: parse all three ARB files and assert key sets match

### Property Test Coverage

Each of the 25 correctness properties above maps to one property-based test. Key generators needed:

- `Arbitrary<String>` for PIN strings (4–6 digits)
- `Arbitrary<double>` for amounts (including boundary values)
- `Arbitrary<Transaction>` with random payment methods, dates, categories
- `Arbitrary<List<ExchangeRateRow>>` with random rates and dates
- `Arbitrary<RecurringTemplateRow>` with random recurrence and last_applied_date
- `Arbitrary<TransactionFilterParams>` with random filter combinations
