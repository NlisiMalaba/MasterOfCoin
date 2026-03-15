# Requirements Document

## Introduction

MasterOfCoin is a Zimbabwe-focused personal finance Flutter app that operates offline-first using SQLite, BLoC/Cubit state management, and dual-currency support (USD and ZWG/Zimbabwe Gold). This initiative makes the app production-ready for Zimbabwean users by addressing security gaps, improving error handling and UX, adding Zimbabwe-specific financial features, and establishing a foundation of test coverage. The scope covers: PIN/biometric app lock, robust input validation and error surfaces, local payment method tagging (EcoCash, OneMoney, InnBucks), informal economy categories, ZWG exchange rate history and volatility dashboard, ZIMRA-compatible tax export, CSV export, transaction search and filter, budget alerts, auto-apply recurring templates, and Shona/Ndebele localization scaffolding.

---

## Glossary

- **App**: The MasterOfCoin Flutter application.
- **User**: A person using MasterOfCoin to manage personal finances in Zimbabwe.
- **Transaction**: A financial record of type income, expense, or transfer stored in the `transactions` table.
- **Transaction_Form**: The UI form used to create or edit a Transaction.
- **Budget**: A spending limit for an expense category over a calendar month, stored in `budget_allocations`.
- **Budget_Alert_Service**: The background service that evaluates budget utilization and schedules notifications.
- **Recurring_Template**: A saved template for a repeating income or expense, stored in `recurring_templates`.
- **Auto_Apply_Service**: The background service that applies due Recurring_Templates as Transactions.
- **Savings_Goal**: A named savings target with a currency and target amount, stored in `savings_goals`.
- **Exchange_Rate**: A ZWG-to-USD rate record stored in the `exchange_rates` table with a timestamp.
- **Exchange_Rate_Service**: The component responsible for fetching, storing, and retrieving Exchange_Rate records.
- **Volatility_Dashboard**: The screen that visualizes Exchange_Rate history as a time-series chart.
- **Payment_Method**: A tag on a Transaction indicating the channel used (e.g., Cash, EcoCash, OneMoney, InnBucks, Bank Transfer).
- **PIN_Lock**: A 4–6 digit numeric passcode that restricts access to the App.
- **Biometric_Lock**: Device fingerprint or face authentication that restricts access to the App.
- **Auth_Gate**: The lock screen overlay shown on app launch or resume when PIN_Lock or Biometric_Lock is enabled.
- **Secure_Storage**: The `flutter_secure_storage` key-value store used to persist the PIN hash and lock preferences.
- **CSV_Exporter**: The component that serializes Transaction records into comma-separated values and shares the file.
- **ZIMRA_Exporter**: The component that produces a ZIMRA-compatible CSV summary for annual tax filing.
- **Search_Filter**: The UI control and query logic that narrows the Transaction list by keyword, category, date range, currency, or Payment_Method.
- **Notification_Service**: The wrapper around `flutter_local_notifications` used to schedule and deliver local notifications.
- **ARB_File**: An Application Resource Bundle file (`.arb`) containing localized string keys and translations.
- **Localization_Service**: The Flutter `AppLocalizations` delegate that resolves strings from ARB_Files at runtime.
- **Dashboard**: The main summary screen showing balances, recent transactions, and key metrics.
- **ZWG**: Zimbabwe Gold — the local currency introduced in 2024, also referred to as ZiG.
- **USD**: United States Dollar — the dominant hard currency used alongside ZWG in Zimbabwe.
- **ZIMRA**: Zimbabwe Revenue Authority — the national tax body requiring annual income and expense declarations.
- **EcoCash**: Zimbabwe's dominant mobile money platform operated by Econet Wireless.
- **OneMoney**: Mobile money platform operated by NetOne.
- **InnBucks**: Mobile money platform operated by Innscor Africa.

---

## Requirements

### Requirement 1: PIN and Biometric App Lock

**User Story:** As a User, I want to protect the App with a PIN or biometric lock, so that my financial data remains private if my phone is accessed by someone else.

#### Acceptance Criteria

1. THE App SHALL provide a settings option to enable PIN_Lock with a 4–6 digit numeric PIN.
2. WHEN PIN_Lock is enabled and the User sets a PIN, THE Secure_Storage SHALL store a bcrypt hash of the PIN, never the raw PIN.
3. WHEN the App is launched or resumed from background after more than 30 seconds, THE Auth_Gate SHALL be displayed if PIN_Lock or Biometric_Lock is enabled.
4. WHEN the User submits a PIN on the Auth_Gate, THE Auth_Gate SHALL compare the bcrypt hash of the submitted PIN against the stored hash and grant access only on a match.
5. IF the User enters an incorrect PIN 5 consecutive times, THEN THE Auth_Gate SHALL lock further attempts for 30 seconds and display the remaining lockout duration.
6. THE App SHALL provide a settings option to enable Biometric_Lock using the device's available biometric sensor (fingerprint or face).
7. WHEN Biometric_Lock is enabled and the Auth_Gate is displayed, THE Auth_Gate SHALL prompt the device biometric API and grant access on successful authentication.
8. IF biometric authentication fails or is unavailable, THEN THE Auth_Gate SHALL fall back to PIN entry if PIN_Lock is also enabled.
9. WHEN the User disables PIN_Lock, THE Secure_Storage SHALL delete the stored PIN hash and lock preferences.
10. WHEN the User changes their PIN, THE Auth_Gate SHALL require the current PIN to be verified before accepting a new PIN.

---

### Requirement 2: Robust Input Validation and Error Surfaces

**User Story:** As a User, I want clear error messages when I enter invalid data in the Transaction_Form, so that I understand what went wrong and can correct it without losing my input.

#### Acceptance Criteria

1. WHEN the User submits the Transaction_Form with an empty or zero amount, THE form SHALL display an inline error message below the amount field and prevent submission.
2. WHEN the User submits the Transaction_Form with an amount that exceeds 999,999,999, THE form SHALL display an inline error message indicating the maximum allowed value.
3. WHEN the User submits the Transaction_Form without selecting a category or income source, THE form SHALL display an inline error message on the relevant field and prevent submission.
4. WHEN the User enters a non-numeric value in the amount field, THE form SHALL reject the input character-by-character and not allow non-numeric characters (except a single decimal point).
5. WHEN the User submits the Transaction_Form with a note exceeding 500 characters, THE form SHALL display an inline error and prevent submission.
6. WHEN a save operation fails due to a database error, THE form SHALL display a dismissible error banner at the top of the screen with a retry option.
7. WHEN the Transaction_Form is in an error state, THE form SHALL preserve all previously entered field values so the User does not need to re-enter data.

---

### Requirement 3: Local Payment Method Tagging

**User Story:** As a User, I want to tag each transaction with the payment method I used (e.g., EcoCash, Cash, Bank Transfer), so that I can track where my money actually lives and how I'm spending it.

#### Acceptance Criteria

1. THE Transaction_Form SHALL include an optional Payment_Method selector with the following options: Cash, EcoCash, OneMoney, InnBucks, Bank Transfer.
2. WHEN a User selects a Payment_Method on a Transaction, THE system SHALL persist the payment_method value on the transaction record.
3. WHEN a User views the Transaction list, THE system SHALL display the Payment_Method tag alongside each transaction that has one set.
4. WHEN a User filters transactions by Payment_Method, THE system SHALL return only transactions matching the selected Payment_Method.
5. WHEN a User edits an existing Transaction, THE Transaction_Form SHALL pre-populate the Payment_Method field with the previously saved value.
6. THE system SHALL allow a Transaction to have no Payment_Method (the field is optional).

---

### Requirement 4: Informal Economy Expense Categories

**User Story:** As a User in Zimbabwe's informal economy, I want expense and income categories that reflect my real financial activities (cash jobs, market sales, remittances), so that I can accurately track my finances.

#### Acceptance Criteria

1. THE system SHALL seed the following informal economy income categories on first install (if not already present): Cash Job, Market Sale, Remittance Received, Diaspora Transfer.
2. THE system SHALL seed the following informal economy expense categories on first install (if not already present): Market Purchase, Street Food, Informal Transport, Remittance Sent.
3. WHEN the User opens the Transaction_Form for an income transaction, THE system SHALL display the informal economy income categories alongside existing income sources.
4. WHEN the User opens the Transaction_Form for an expense transaction, THE system SHALL display the informal economy expense categories alongside existing expense categories.
5. THE seeded informal economy categories SHALL be marked as system categories (is_system = 1) and SHALL NOT be deletable by the User.
6. WHEN the User navigates to Expense Categories in Settings, THE system SHALL display the informal economy categories with a distinguishing label or icon.

---

### Requirement 5: ZWG Exchange Rate History and Volatility Dashboard

**User Story:** As a User, I want to see how the ZWG/USD exchange rate has changed over time, so that I can understand currency volatility and make informed financial decisions.

#### Acceptance Criteria

1. WHEN the User saves a new exchange rate in Settings, THE Exchange_Rate_Service SHALL insert a new record into the `exchange_rates` table with the rate value and current timestamp.
2. THE `exchange_rates` table SHALL store at minimum: id, rate (REAL), date (INTEGER unix seconds), created_at (INTEGER unix seconds).
3. THE App SHALL provide a Volatility_Dashboard screen accessible from Settings or the Dashboard.
4. WHEN the Volatility_Dashboard is displayed, THE system SHALL render a line chart (using fl_chart) showing the ZWG/USD rate over time, with date on the x-axis and rate on the y-axis.
5. WHEN the Volatility_Dashboard is displayed and fewer than 2 data points exist, THE system SHALL display an empty-state message prompting the User to update the exchange rate over time.
6. WHEN the Volatility_Dashboard is displayed, THE system SHALL show the percentage change between the oldest and newest rate in the visible range.
7. WHEN the User views the Volatility_Dashboard, THE system SHALL display the most recent rate prominently at the top of the screen.
8. THE Volatility_Dashboard SHALL support filtering by time range: Last 30 days, Last 90 days, All time.

---

### Requirement 6: ZIMRA-Compatible Tax Export

**User Story:** As a User, I want to export my annual income and expense summary in a format compatible with ZIMRA tax filing, so that I can meet my tax obligations without manual data entry.

#### Acceptance Criteria

1. THE App SHALL provide a ZIMRA Export option in Settings or the Analytics screen.
2. WHEN the User initiates a ZIMRA Export, THE system SHALL prompt the User to select a tax year (calendar year).
3. WHEN the User confirms the ZIMRA Export, THE ZIMRA_Exporter SHALL generate a CSV file with the following columns: Date, Type (Income/Expense), Category, Amount, Currency, Note.
4. THE ZIMRA_Exporter SHALL produce one row per transaction for the selected year, ordered by date ascending.
5. WHEN the ZIMRA CSV is generated, THE system SHALL share the file using the device share sheet (share_plus) so the User can save or send it.
6. THE ZIMRA CSV header row SHALL use the exact column names: Date,Type,Category,Amount,Currency,Note.
7. WHEN the selected year has no transactions, THE ZIMRA_Exporter SHALL generate a CSV with only the header row and notify the User that no data was found.

---

### Requirement 7: CSV Export of Transactions by Date Range

**User Story:** As a User, I want to export my transactions for a custom date range as a CSV file, so that I can use the data in spreadsheets or share it with an accountant.

#### Acceptance Criteria

1. THE App SHALL provide a CSV Export option accessible from the Transactions list screen.
2. WHEN the User initiates a CSV Export, THE system SHALL display a date range picker allowing the User to select a start date and end date.
3. WHEN the User confirms the date range, THE CSV_Exporter SHALL query all transactions within the range (inclusive of start and end dates) and generate a CSV file.
4. THE CSV file SHALL include the following columns: Date, Type, Amount, Currency, Category, PaymentMethod, Note.
5. WHEN the CSV is generated, THE system SHALL share the file using the device share sheet (share_plus).
6. WHEN the selected date range has no transactions, THE CSV_Exporter SHALL generate a CSV with only the header row and display a snackbar informing the User.
7. THE CSV_Exporter SHALL format dates as YYYY-MM-DD and amounts as decimal numbers with 2 decimal places.

---

### Requirement 8: Transaction Search and Filter

**User Story:** As a User, I want to search and filter my transactions by keyword, category, date range, currency, and payment method, so that I can quickly find specific transactions as my history grows.

#### Acceptance Criteria

1. THE Transactions list screen SHALL include a search bar that filters transactions by keyword match against the transaction note field.
2. WHEN the User types in the search bar, THE system SHALL update the transaction list in real time (debounced by 300ms) to show only matching transactions.
3. THE Transactions list screen SHALL include filter controls for: Category, Date Range, Currency (USD/ZWG), and Payment_Method.
4. WHEN the User applies one or more filters, THE system SHALL combine all active filters with AND logic and update the transaction list.
5. WHEN the User clears all filters and the search bar, THE system SHALL restore the full unfiltered transaction list.
6. WHEN no transactions match the active search/filter criteria, THE system SHALL display an empty-state message indicating no results were found.
7. WHEN the User navigates away from the Transactions screen and returns, THE system SHALL restore the previously active search and filter state.
8. THE search and filter state SHALL be held in the Transactions screen's Cubit and SHALL NOT persist across app restarts.

---

### Requirement 9: Budget Alerts via Local Notifications

**User Story:** As a User, I want to receive a local notification when my spending in a budget category reaches 80% of the monthly limit, so that I can adjust my spending before exceeding the budget.

#### Acceptance Criteria

1. THE App SHALL request notification permissions from the device on first launch after the Notification_Service is initialized.
2. WHEN a Transaction of type expense is saved, THE Budget_Alert_Service SHALL check whether the total spending in the transaction's category for the current month has reached or exceeded 80% of the budget allocation for that category.
3. WHEN the 80% threshold is reached or exceeded, THE Notification_Service SHALL schedule a local notification with the title "Budget Alert" and a body indicating the category name and percentage used.
4. THE Budget_Alert_Service SHALL NOT send duplicate notifications for the same category in the same calendar month (once per category per month).
5. WHEN the User taps the budget alert notification, THE App SHALL navigate to the Budgets screen.
6. WHEN no budget allocation exists for a category, THE Budget_Alert_Service SHALL skip the alert check for that category.
7. THE Notification_Service SHALL use `flutter_local_notifications` and SHALL NOT require an internet connection.

---

### Requirement 10: Auto-Apply Recurring Templates

**User Story:** As a User, I want my recurring income and expense templates to be automatically applied as transactions when they are due, so that I don't have to manually add them each week or month.

#### Acceptance Criteria

1. THE App SHALL register a WorkManager periodic task named `auto_apply_recurring` that runs at most once per day.
2. WHEN the `auto_apply_recurring` task runs, THE Auto_Apply_Service SHALL query all Recurring_Templates and determine which are due based on their `recurrence` (weekly/monthly) and `last_applied_date`.
3. A weekly Recurring_Template SHALL be considered due if `last_applied_date` is null or more than 7 days before the current date.
4. A monthly Recurring_Template SHALL be considered due if `last_applied_date` is null or in a previous calendar month relative to the current date.
5. WHEN a Recurring_Template is due, THE Auto_Apply_Service SHALL insert a new Transaction with the template's type, amount, currency, category_id, and note, and set the transaction date to the current date.
6. WHEN a Recurring_Template is applied, THE Auto_Apply_Service SHALL update the template's `last_applied_date` to the current date.
7. WHEN one or more Recurring_Templates are auto-applied, THE Notification_Service SHALL deliver a local notification summarizing how many templates were applied.
8. THE Auto_Apply_Service SHALL be idempotent: running it multiple times on the same day SHALL NOT create duplicate transactions for the same template.

---

### Requirement 11: Shona/Ndebele Localization Scaffolding

**User Story:** As a User who speaks Shona or Ndebele, I want the App to be available in my language, so that I can manage my finances more comfortably in my native tongue.

#### Acceptance Criteria

1. THE App SHALL include ARB_Files for three locales: English (app_en.arb), Shona (app_sn.arb), and Ndebele (app_nd.arb).
2. THE app_sn.arb and app_nd.arb files SHALL contain translations for all string keys present in app_en.arb.
3. THE Settings screen SHALL include a Language selector allowing the User to choose between English, Shona, and Ndebele.
4. WHEN the User selects a language, THE App SHALL update the locale immediately without requiring a restart.
5. THE selected language SHALL be persisted in app_settings and restored on next launch.
6. WHEN the App starts and no language preference is stored, THE App SHALL default to English.
7. ALL user-visible strings in the App SHALL be referenced via the Localization_Service (AppLocalizations) rather than hardcoded string literals, for all screens covered by this spec.
