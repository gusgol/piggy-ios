# 🐷 Piggy for iOS: Personal Expense Tracker

The iOS port of Piggy, built with SwiftUI. It's being ported from the Android app one feature at a time, as a learning project. The code includes comments comparing it to the Android version.

## 📱 Features

- **Expense Tracking**: track and categorize your daily expenses
- **Categories Management**: organize expenses by custom categories
- **Trends Analysis**: visualize spending patterns with Swift Charts
- **AI Import**: import expenses from files and photos with Firebase AI Logic

## 🧱 Stack

| Concern | iOS | Android counterpart |
|---|---|---|
| UI | SwiftUI | Jetpack Compose |
| State | `@Observable` | `StateFlow` |
| Async | `async`/`await`, `AsyncThrowingStream` | Coroutines, `Flow` |
| DI | `@Entry` `EnvironmentValues` | Hilt |
| Navigation | `NavigationStack` + `TabView` | Navigation3 |
| Backend | Firebase Auth, Firestore, AI Logic | Same |
| Dependencies | Swift Package Manager | Gradle version catalog |

## 🏗️ Structure

```
Piggy/
├── App/            # App entry, auth gate, tab shell, routes
├── Core/
│   ├── Auth/       # User model, auth repository, session
│   ├── Domain/     # Models + repository protocols (Firebase-agnostic)
│   ├── Data/       # Firestore + AI implementations
│   ├── DI/         # EnvironmentValues entries
│   └── DesignSystem/
└── Feature/        # Auth, Expenses, Categories, Trends
```

## 🚀 Getting started

1. Open `Piggy.xcodeproj` in Xcode. Swift packages resolve automatically.
2. Add the Firebase config. `GoogleService-Info.plist` is git-ignored, so you need your own copy:
   - In the Firebase console, open the project's iOS app (bundle ID `com.goldhardt.Piggy`) and download `GoogleService-Info.plist`.
   - Put it in `Piggy/`.
3. Build and run on an iOS simulator.

## 🗺️ Roadmap

- [x] Project foundation: packages, Firebase, domain models, repository protocols
- [ ] Auth: Google Sign-In + Sign in with Apple
- [ ] Expenses CRUD
- [ ] Categories
- [ ] Trends
- [ ] AI Import
- [ ] Settings & polish
