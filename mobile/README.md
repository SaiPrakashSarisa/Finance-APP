# Finance Hub Enterprise — Production Flutter Mobile Application

A mobile-first Flutter application engineered specifically for smartphones, adopting the **Stitch Finance Hub Enterprise (Luminous Ledger)** design system.

---

## 🌟 Key Features & Design System
- **Mobile-First UX**: Thumb-friendly bottom navigation bar shell with a persistent floating quick action button (FAB) for 1-tap financial actions.
- **Stitch Luminous Ledger Aesthetic**:
  - Deep Slate / Obsidian Dark Suite (`#0B1326`)
  - Glassmorphic panels with subtle backdrop blur & 10% white edge stroke (`AppColors.glassPanelBg`, `AppColors.glassBorder`)
  - Accent colors: Primary Violet (`#6366F1`), Income Emerald (`#4EDEA3`), Expense Rose (`#FFB2B7`), Transfer Amber (`#F59E0B`), Credit Cyan (`#06B6D4`)
  - Google Fonts `Outfit` typography
- **Core Domain Modules**:
  1. **Home Dashboard**: Total net worth hero card with ambient neon glow, quick action buttons, horizontal accounts slider, and recent transactions.
  2. **Transactions Ledger**: Multi-filter transaction list, search input, itemized receipt drawer, and full **CSV Backup Export & Restore**.
  3. **Itemized Receipt Builder**: Dynamic product line-item builder with quantity, unit price, unit, and automated sum calculation.
  4. **Budgets & Debt Tracker**: Category spending limits with progress indicators & Receivables/Liabilities debt manager with quick repayment triggers.
  5. **Financial Intelligence Hub**: Category expense pie chart, item price inflation tracker, and recurring subscription detector.
  6. **Profile & Settings**: User profile edit, security/password update, dashboard date range preferences, and secure sign out.

---

## 🏗️ Architecture & Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── api_endpoints.dart    # Centralized REST API routes
│   │   └── app_colors.dart       # Stitch Finance Hub Enterprise design tokens
│   ├── network/
│   │   └── api_client.dart       # Dio HTTP client with JWT Bearer Interceptor
│   └── router/
│       └── app_router.dart       # GoRouter route hierarchy & ShellRoute setup
├── data/
│   ├── models/                   # Strongly typed Dart Data Models
│   │   ├── account_model.dart
│   │   ├── analytics_model.dart
│   │   ├── budget_model.dart
│   │   ├── category_model.dart
│   │   ├── credit_model.dart
│   │   ├── transaction_model.dart
│   │   └── user_model.dart
│   └── repositories/             # API Data Access Layer
│       ├── account_repository.dart
│       ├── analytics_repository.dart
│       ├── auth_repository.dart
│       ├── budget_repository.dart
│       ├── category_repository.dart
│       ├── credit_repository.dart
│       ├── transaction_repository.dart
│       └── user_repository.dart
├── presentation/
│   ├── providers/                # Riverpod State Notifiers
│   │   ├── account_provider.dart
│   │   ├── analytics_provider.dart
│   │   ├── auth_provider.dart
│   │   ├── budget_provider.dart
│   │   ├── category_provider.dart
│   │   ├── credit_provider.dart
│   │   ├── transaction_provider.dart
│   │   └── user_provider.dart
│   └── screens/                  # Mobile-First Screens
│       ├── add_transaction_screen.dart
│       ├── analytics_screen.dart
│       ├── budgets_credits_screen.dart
│       ├── dashboard_screen.dart
│       ├── login_screen.dart
│       ├── main_shell_screen.dart
│       ├── profile_settings_screen.dart
│       ├── register_screen.dart
│       ├── splash_screen.dart
│       └── transactions_screen.dart
└── main.dart                     # App entry point with GoogleFonts Outfit theme
```

---

## ⚡ Setup & Local Run Instructions

### 1. Prerequisites
- Flutter SDK `>=3.0.0`
- Existing Node.js Backend running on `http://localhost:5000`

### 2. Install Dependencies
```bash
cd mobile
flutter pub get
```

### 3. Run Application
- **Android Emulator**:
  ```bash
  flutter run
  ```
  *(Communicates with backend via `http://10.0.2.2:5000/api`)*

- **iOS Simulator / Web**:
  ```bash
  flutter run -d chrome
  # or
  flutter run -d iPhone
  ```
  *(Communicates with backend via `http://localhost:5000/api`)*

### 4. Execute Unit Tests
```bash
flutter test
```
