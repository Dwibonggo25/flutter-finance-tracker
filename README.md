# Finance Project

<p align="center">
  <img src="assets/branding/app_icon_master.png" alt="Finance Project app icon" width="128" />
</p>

A scalable Flutter foundation for a personal finance tracker, using layered
architecture, dependency injection, Firebase Authentication, Cloud Firestore,
and REST API integration.

## Highlights

- Feature-first project organization
- Data, domain, and presentation layers
- BLoC for predictable state management
- Firebase Authentication with email and password
- User-scoped Cloud Firestore transaction storage
- Real-time create, read, update, delete, search, and filtering for transactions
- Monthly category budgets with usage warnings
- Animated cash-flow reports, category breakdowns, and month comparisons
- Monthly recurring transactions with due-date reminders
- CSV and PDF report export through the native share sheet
- Profile management for photo, name, email, password, and address
- Editable expense categories stored per user in Cloud Firestore
- Optional authenticated AI help chat through Firebase Functions and OpenAI
- Reusable Rupiah formatting for all amount inputs
- Indonesian and English localization with a persistent language preference
- Flutter Modular for routing and dependency injection
- Dio client with an authentication interceptor
- Development, UAT, and production entry points
- Compile-time configuration without committing API keys
- Shared preferences and secure-storage foundations

## Tech stack

- Flutter and Dart
- Firebase Authentication and Cloud Firestore
- Flutter BLoC
- Flutter Modular
- Dio
- Equatable
- Connectivity Plus
- Flutter Secure Storage
- Shared Preferences
- ScreenUtil and Google Fonts

## Project structure

```text
lib/
├── app/
│   ├── launcher/                 # Environment-specific entry points
│   ├── app_module.dart           # Global dependency injection and routes
│   └── app_widget.dart           # Root application widget
├── features/
│   ├── home/                     # Dashboard and finance UI
│   ├── budgets/                  # Monthly Firestore budget data
│   ├── categories/               # User-managed expense categories
│   ├── help/                     # Authenticated AI help chat
│   ├── recurring_transactions/   # Schedules, Firestore data, and reminder UI
│   ├── reports/                  # CSV/PDF report generation
│   ├── profile/                  # Firebase profile and account settings
│   └── transactions/
│       ├── data/                 # Firestore repository implementation
│       └── domain/               # Transaction entity and repository contract
└── libraries/
    ├── core/                     # Configuration, localization, networking, storage
    └── dependencies/             # Shared dependency registration
```

## Prerequisites

- Flutter SDK compatible with Dart `^3.9.2`
- Android Studio or another Flutter-compatible IDE
- An OpenWeather API key
- A Firebase project with Email/Password Authentication enabled
- A Cloud Firestore database

## Getting started

1. Clone the repository and enter the project directory.

   ```bash
   cd finance_project
   ```

2. Install dependencies.

   ```bash
   flutter pub get
   ```

3. Create the local development configuration.

   ```bash
   cp config/example.json config/dev.json
   ```

4. Replace the placeholder values in `config/dev.json` with your OpenWeather
   key and Firebase web app configuration.

5. Run the development entry point.

   ```bash
   flutter run \
     --flavor dev \
     -t lib/app/launcher/main_dev.dart \
     --dart-define-from-file=config/dev.json
   ```

   Android Studio users can select the shared **Finance Project - Dev** run
   configuration and use Run or Debug. It supplies the same flavor, entry
   point, and development configuration while keeping hot reload available.

## Android Studio configuration

Open **Run > Edit Configurations** and add the following to **Additional run
args** for the development configuration:

```text
--dart-define-from-file=config/dev.json
```

Set the build flavor to `dev`.

Set the Dart entry point to:

```text
lib/app/launcher/main_dev.dart
```

## Configuration and secrets

`config/dev.json` is excluded from version control. Only
`config/example.json`, which contains a placeholder value, is committed.

Values supplied with `--dart-define` are embedded in the compiled application.
For production credentials that must remain secret, use a backend service rather
than distributing the credential in a mobile application.

## Firebase Authentication setup

1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Open **Authentication > Sign-in method**, then enable **Email/Password**.
3. In **Project settings > General**, register the Android development app with
   package name `com.dwibonggo.financeproject.dev`. Copy the Android app values
   into `config/dev.json` (the API key, mobile SDK app ID, project number,
   project ID, and storage bucket are also present in `google-services.json`):

   ```json
   {
     "FIREBASE_API_KEY": "...",
     "FIREBASE_APP_ID": "...",
     "FIREBASE_MESSAGING_SENDER_ID": "...",
     "FIREBASE_PROJECT_ID": "...",
     "FIREBASE_AUTH_DOMAIN": "...",
     "FIREBASE_STORAGE_BUCKET": "..."
   }
   ```

The login screen supports account registration, sign-in, password reset,
session restoration, and sign-out. The development Android application ID is
`com.dwibonggo.financeproject.dev`; production uses
`com.dwibonggo.financeproject`.

## Cloud Firestore setup

1. Open **Firebase Console > Build > Firestore Database**.
2. Create a database and select a region close to your users.
3. Publish the contents of `firestore.rules` from the Firebase Console Rules
   tab, or deploy it with the Firebase CLI:

   ```bash
   firebase deploy --only firestore:rules --project YOUR_FIREBASE_PROJECT_ID
   ```

Transactions are stored under `users/{uid}/transactions/{transactionId}`,
monthly budgets under `users/{uid}/budgets/{yyyy-MM}`, and recurring schedules
under `users/{uid}/recurringTransactions/{transactionId}`. Expense categories
are stored under `users/{uid}/expenseCategories/{categoryId}`. The included rules
require authentication and only allow a user to access their own finance data.

## AI help setup

The mobile application never contains the OpenAI API key. Questions are sent
with the signed-in user's Firebase ID token to the included Firebase HTTPS
Function, and only that backend reads the secret.

Install and deploy the function:

```bash
cd functions
npm install
cd ..
firebase functions:secrets:set OPENAI_API_KEY
firebase deploy --only functions:askFinanceAssistant --project YOUR_FIREBASE_PROJECT_ID
```

Copy the deployed HTTPS function URL into the local configuration:

```json
{
  "AI_HELP_URL": "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/askFinanceAssistant",
  "ENABLE_AI_HELP": true
}
```

AI Help is hidden by default. Set `ENABLE_AI_HELP` to `true` only after the
backend URL and secret are ready.

Keep `config/dev.json` private. Firebase Functions deployment may require the
Firebase project to use the Blaze billing plan.

## Reminders and exports

Tap the bell in the dashboard app bar to manage recurring monthly income or
expenses. Each active item schedules its next local reminder. Android and iOS
will request notification permission when a reminder is enabled.

Open **Reports**, apply the period/category filter, then use the share icon to
export the filtered data as CSV or PDF. Temporary export files are handed to
the platform share sheet.

The portfolio recording and screenshot checklist is in [`docs/DEMO.md`](docs/DEMO.md).

## Profile photo storage

Enable Firebase Storage in the same Firebase project, then deploy both security
rule files:

```bash
firebase deploy --only firestore:rules,storage --project YOUR_FIREBASE_PROJECT_ID
```

Profile photos are limited to authenticated image uploads smaller than 5 MB.
Email and password changes require the current password. Firebase sends a
verification link before applying a new email address.

## Quality checks

Run static analysis before committing changes:

```bash
flutter analyze
```

Run automated unit and widget tests:

```bash
flutter test
```

## Next ideas

- Add bank synchronization through a licensed provider
- Add biometric app lock and encrypted offline caching
- Add home-screen widgets for balances and upcoming bills
