# MasterOfCoin

A Zimbabwe-focused personal finance app with dual-currency (USD/ZWG) support. Offline-first Flutter Android application for budget tracking, savings goals, and analytics.

## Features

- **Dual Currency**: USD and ZWG (Zimbabwe Gold)
- **Transactions**: Income and expense tracking with categories
- **Income Sources**: Job, side hustle, investments - multiple sources per currency
- **Savings Goals**: Set targets, deadlines, and allocate from income
- **Budget Allocation**: Envelope-style monthly budgets per expense category
- **Analytics**: Spending by category, income vs expense trends, pie and bar charts
- **Recurring Templates**: Create templates for weekly/monthly transactions
- **Dashboard**: Total balance, this-month summary, quick navigation
- **Settings**: Default currency, ZWG/USD exchange rate, manage categories and income sources
- **Offline-first**: All data stored locally with SQLite

## Setup

1. Install [Flutter](https://flutter.dev/docs/get-started/install) (3.24+).

2. From the project root, run:
   ```bash
   flutter pub get
   ```

3. To generate launcher icons (optional), run:
   ```bash
   flutter create . --platforms android
   ```
   This will add default Android resources if any are missing.

4. Run on Android device or emulator:
   ```bash
   flutter run
   ```

## Project Structure

- `lib/core/` - Database, DI, theme, utilities
- `lib/features/` - Feature modules (dashboard, transactions, budgets, etc.)
- `lib/shared/` - Shared domain types (Currency, TransactionType)

## Architecture

Clean Architecture with feature-first organization. BLoC/Cubit for state management, SQLite for persistence.
