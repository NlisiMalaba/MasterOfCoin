# MasterOfCoin

A personal finance and budget tracker. Track income, expenses, savings goals, and spending across **USD** and **ZWG** (Zimbabwe Gold). Works fully offline—all data is stored on your device.

## Flutter Version

Install **Flutter 3.24 or newer** (Stable channel).

The project requires Dart SDK `>=3.4.0`, which ships with Flutter 3.22+. Using Flutter 3.24+ is recommended.

To check your version:
```bash
flutter --version
```

## Features

| Feature | Description |
|---------|-------------|
| **Dual Currency** | Track money in USD and ZWG |
| **Transactions** | Add income and expenses with categories, dates, and notes |
| **Income Sources** | Multiple sources (job, side hustle, investments) per currency |
| **Savings Goals** | Set targets and deadlines, allocate income to goals |
| **Budgets** | Monthly envelope budgets per expense category |
| **Analytics** | Spending by category, income vs expense trends, charts |
| **Recurring** | Templates for weekly or monthly transactions (rent, salary, etc.) |
| **Dashboard** | Balance overview and quick access to main screens |
| **Offline-first** | All data stored locally—no internet required |

## Prerequisites

- **Flutter** 3.24+ (Stable)
- **Android Studio** or VS Code with Flutter plugin
- Android SDK (API 21+)
- Android device or emulator

## Setup

1. **Clone the repository** (or open the project folder):
   ```bash
   cd F:\Sources\MasterOfCoin
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Optional: Ensure Android resources exist**  
   If the app fails to build, regenerate project files:
   ```bash
   flutter create . --platforms android
   ```

## Run the App

1. Connect an Android device or start an emulator.

2. Run the app:
   ```bash
   flutter run
   ```

3. For a release build (APK):
   ```bash
   flutter build apk
   ```
   The APK is in `build/app/outputs/flutter-apk/app-release.apk`.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # MaterialApp and router
├── core/                     # Shared infrastructure
│   ├── database/             # SQLite, migrations, DAOs
│   ├── di/                   # Dependency injection
│   ├── theme/                # App theme
│   ├── router/               # Navigation
│   └── ...
├── features/                 # Feature modules
│   ├── dashboard/
│   ├── transactions/
│   ├── savings_goals/
│   ├── budgets/
│   ├── analytics/
│   ├── recurring/
│   ├── settings/
│   └── onboarding/
└── shared/                   # Shared domain (Currency, TransactionType)
```

## Architecture

- **Clean Architecture** with feature-first organization
- **BLoC/Cubit** for state management
- **SQLite** (sqflite) for local persistence
- **go_router** for navigation
