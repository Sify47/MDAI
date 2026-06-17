# 🚀 VITA Development Suggestions

## ✅ Recently Completed
- Changed app identity from purple to **blue + green**
- Fixed password validation in registration screen
- Removed duplicate "نسيت كلمة المرور" in login screen
- Fixed "التالي" button text visibility in initial setup
- Redesigned splash screen

---

## 1️⃣ Code Refactoring — Highest Priority

Current files are too large and need splitting:

| File | Size | Issue |
|------|------|-------|
| `home_screen_with_animations.dart` | **3240 lines** | Contains data, UI, animations, services — everything |
| `chat_main_screen.dart` | **2156 lines** | Mixed logic + UI |
| `profile_screen.dart` | **1273 lines** | Needs settings separation |
| `services_screen.dart` | **823 lines** | Moderately large |

**Solution**: Use **Repository + ViewModel** pattern per screen:
```
lib/
  screens/
    home/
      home_screen.dart          ← UI only
      home_view_model.dart      ← display logic
      home_repository.dart      ← data fetching
    chat/
      chat_screen.dart
      chat_view_model.dart
      chat_repository.dart
```

---

## 2️⃣ State Management Improvement

Currently uses basic `Provider` + `ChangeNotifier`.

**Suggestion**: Use `Riverpod` or `Bloc` for:
- Better async data handling (no more `setState` everywhere)
- Complete separation of business logic from UI
- Easier testing
- Automatic stream disposal

---

## 3️⃣ Routing System

Currently uses raw `Navigator.push` with no centralized routing.

**Suggestion**: Use `go_router`:
```dart
final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (_, __) => const MainScreen()),
  ],
);
```

**Benefits**: Deep linking, auth guards, smooth transitions, better back button handling.

---

## 4️⃣ Fix `main.dart` — Use `AppTheme`

Currently `main.dart` redefines the theme manually instead of using the existing `AppTheme` class in `colors.dart`.

**Suggestion**:
```dart
return MaterialApp(
  theme: themeProvider.isDarkMode 
      ? AppTheme.darkTheme   // Create darkTheme in colors.dart
      : AppTheme.lightTheme,
  home: const SplashScreen(),
);
```

---

## 5️⃣ Fix `ThemeProvider`

Current issues:
- Custom fragile JSON parser using `replaceAll` and `split`
- Saves `Map.toString()` instead of real JSON
- Singleton pattern unnecessary with Provider

**Suggestion**: Use `shared_preferences` with proper `jsonEncode`/`jsonDecode`.

---

## 6️⃣ New Features

| Feature | Description | Priority |
|---------|-------------|----------|
| **📱 Smartwatch Support** | Wear OS / Apple Watch integration for steps & heart rate | 🟡 Medium |
| **🔔 Medication Reminders** | Medicine time alerts with confirmation | 🟢 High |
| **📊 Export Reports** | PDF/Excel for monthly health reports | 🟢 High |
| **👨‍⚕️ Appointment Booking** | Connect with clinics/doctors | 🟡 Medium |
| **🌙 Enhanced Dark Mode** | Full dark mode with consistent colors | 🟢 High |
| **🗺️ Pharmacy Map** | Nearest pharmacies/hospitals | 🟠 Low |
| **📱 Home Screen Widgets** | Android/iOS widgets | 🟡 Medium |
| **🌐 Multi-language** | English support alongside Arabic | 🟠 Low |

---

## 7️⃣ Performance Improvements

- **Lazy loading**: Load data on demand instead of everything in `initState`
- **Caching**: Use `cached_network_image` for images
- **Shimmer/Skeleton**: Already exists in `skeleton_loading.dart` — extend to all screens
- **Debouncing**: For search in `services_screen.dart`

---

## 8️⃣ Security Enhancements

- **Token refresh**: Auto-refresh mechanism
- **Biometric auth**: Fingerprint / Face ID support
- **Data encryption**: `encrypt` and `crypto` packages already in `pubspec.yaml` but not fully utilized

---

## 9️⃣ Testing

Currently only default `widget_test.dart` exists.

**Suggestion**:
```
test/
  unit/
    services/
      auth_api_test.dart
      nutrition_calculator_test.dart
  widget/
    screens/
      login_screen_test.dart
      register_screen_test.dart
  integration/
    auth_flow_test.dart
```

---

## 🔟 Backend Improvements

Backend is in `back/` using FastAPI. Suggestions:
- Add **API versioning** (`/api/v1/...`)
- Full **Swagger/OpenAPI** documentation (FastAPI supports natively)
- Add **rate limiting**
- Improve **error handling** with unified error messages

---

## 📋 Phased Development Plan

```
Phase 1 — Fundamentals (1-2 weeks):
  □ Split home_screen.dart (3240 lines)
  □ Fix ThemeProvider (JSON parsing)
  □ Use AppTheme in main.dart

Phase 2 — UX Improvements (1-2 weeks):
  □ Complete dark mode
  □ Improve loading/shimmer across all screens
  □ Add medication reminders

Phase 3 — Infrastructure (1-2 weeks):
  □ Add go_router for routing
  □ Improve state management (Riverpod/Bloc)
  □ Add unit tests

Phase 4 — Advanced Features (2-3 weeks):
  □ PDF report export
  □ Biometric auth
  □ Home screen widgets