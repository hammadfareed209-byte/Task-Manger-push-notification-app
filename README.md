# Task Manager App (Flutter + SQLite)

A modern, sleek dark-mode Android Task Management application with local persistent SQLite storage and ready-to-wire push notifications.

## Features
- **Modern Dark UI**: Deep charcoal background (`#121212`), warm amber/gold accents (`#E5A93C`), and subtle card containers.
- **Auth Screen**:
  - Interactive smooth tab switcher between Sign In & Sign Up
  - Form validation with obscure password toggle
  - "Remember me" checkbox & "Forgot?" helper
  - Social login options (Google, Apple, Biometric)
- **SQLite Database (`sqflite`)**:
  - Pre-configured table schema storing task title, description, due date, completion status, repeat rule, and priority level.
  - Pre-seeded starter tasks so you can see live data immediately on first launch.
- **Dashboard Views**:
  - **Today Tasks**: Filters tasks due today or overdue.
  - **Completed Tasks**: Archives all finished tasks.
  - **Repeated Tasks**: Isolates daily, weekly, and monthly recurring routines.
- **Task Management**:
  - Create tasks with custom due dates, time pickers, priorities, and repeat settings.
  - Instant checkbox toggle with SQLite persistence.
  - Delete action per task.

## Project Structure
```
task_manager_app/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   └── task_model.dart
│   ├── services/
│   │   ├── database_helper.dart
│   │   └── notification_service.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── screens/
│       ├── auth/
│       │   └── auth_screen.dart
│       └── dashboard/
│           ├── dashboard_screen.dart
│           ├── widgets/
│           │   └── task_tile.dart
│           └── views/
│               ├── today_view.dart
│               ├── completed_view.dart
│               └── repeated_view.dart
└── pubspec.yaml
```

## How to Run
1. Navigate into the folder:
   ```bash
   cd "C:\Users\Hamad Fareed\.gemini\antigravity\scratch\task_manager_app"
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run on your connected Android device or emulator:
   ```bash
   flutter run
   ```
