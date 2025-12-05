# Flutter Starter Template - v0.2

A production-ready Flutter starter template with robust navigation, route guards, and clean architecture.

## What's in v0.2

**Navigation & Routing Foundation** - Complete implementation of:
-  Dynamic route registry from feature manifests
-  Priority-based navigation guards (onboarding → auth → no-auth)
-  Launch state machine with smart initial route detection
-  Deep link-ready architecture
-  UI-agnostic navigation service

**Features Implemented:**
-  Onboarding flow (complete/skip)
-  Login screen (email/password with validation)
-  Home screen (authenticated)
-  Route guards preventing unauthorized access

**Testing:**
-  70%+ test coverage on navigation logic
-  Integration tests for critical user flows
-  Guard priority and redirect logic validated

##  Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart 3.0 or higher

##  Quick Start

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Run the App

```bash
flutter run
```

### 3. Run Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/app/navigation/guards_test.dart

# With coverage
flutter test --coverage
```

##  Architecture Overview

### Boot Sequence

The app follows a 4-phase boot sequence in `main.dart`:

```
1. Setup Dependencies → DI container initialization
2. Resolve Launch State → Config + Onboarding + Auth checks
3. Create Router → Build route table with guards
4. Run App → Launch MaterialApp with router
```

### Navigation Flow

```
User Request → Guards (by priority) → Allowed/Redirect → Navigate
                ↓
         [OnboardingGuard (0)]
                ↓
         [AuthGuard (10)]
                ↓
         [NoAuthGuard (20)]
```

### Project Structure

```
lib/
├── app/                    # Composition root
│   ├── boot/              # Launch state machine
│   ├── navigation/        # Router & guards
│   ├── services/          # Mock service implementations
│   ├── app.dart           # Root widget
│   └── di.dart            # Dependency injection
├── core/                   # Contracts & primitives
│   ├── contracts/         # Service interfaces
│   ├── errors/            # Error taxonomy
│   ├── network/           # HTTP abstractions
│   └── runtime/           # Launch state, etc.
└── features/              # Feature modules
    ├── onboarding/
    ├── auth/
    └── home/
```

##  Usage Examples

### Adding a New Route

1. **Create the manifest** in your feature:

```dart
// lib/features/profile/manifest.dart
class ProfileManifest {
  static const String routePath = '/profile';
  static const String routeId = 'profile';
  static const List<String> guards = ['requiresAuth'];
}
```

2. **Add to route registry** in `lib/app/navigation/router.dart`:

```dart
final routeIdToPath = {
  // ... existing routes
  'profile': '/profile',
};

// Add route configuration
GoRoute(
  path: '/profile',
  builder: (context, state) => ProfileScreen(...),
),
```

3. **Navigate from anywhere**:

```dart
navigationService.goToRoute('profile');
```

### Creating a Custom Guard

```dart
class FeatureFlagGuard implements NavigationGuard {
  final ConfigService _config;
  
  FeatureFlagGuard(this._config);

  @override
  Future<GuardResult> evaluate(
    String targetRouteId,
    String? currentRouteId,
  ) async {
    if (targetRouteId == 'beta_feature') {
      final enabled = _config.getFlag('beta_feature_enabled');
      if (!enabled) {
        return const GuardRedirect('home');
      }
    }
    return const GuardAllow();
  }

  @override
  int get priority => 30; // After standard guards

  @override
  String get name => 'FeatureFlagGuard';
}
```

##  Testing Approach

### Unit Tests

Test individual guards, state logic, and services:

```dart
test('AuthGuard redirects unauthenticated users', () async {
  when(() => auth.isAuthenticated).thenAnswer((_) async => false);
  
  final result = await guard.evaluate('home', null);
  
  expect(result, isA<GuardRedirect>());
});
```

### Integration Tests

Test complete navigation flows:

```dart
testWidgets('Login flow works end-to-end', (tester) async {
  // Setup app
  await tester.pumpWidget(app);
  
  // Enter credentials
  await tester.enterText(emailField, 'test@example.com');
  await tester.enterText(passwordField, 'password123');
  
  // Submit
  await tester.tap(loginButton);
  await tester.pumpAndSettle();
  
  // Verify navigation to home
  expect(find.text('Welcome back!'), findsOneWidget);
});
```

##  Key Concepts

### Launch State

Captures app state at boot time:

```dart
LaunchState(
  onboardingSeen: true,
  isAuthenticated: false,
  initialDeepLink: null,
)
```

The state machine determines the initial route:
- Not onboarded → `/onboarding`
- Onboarded + authenticated → `/home`
- Onboarded + not authenticated → `/login`

### Guards

Guards control access to routes based on app state:

- **OnboardingGuard**: Ensures first-run experience is complete
- **AuthGuard**: Requires valid session, attempts silent refresh
- **NoAuthGuard**: Keeps authenticated users away from login

### Service Contracts

All external dependencies are behind interfaces in `core/contracts/`:

```dart
abstract interface class AuthService {
  Future<bool> get isAuthenticated;
  Future<void> login(String email, String password);
  Future<void> logout();
  Future<void> refreshSession();
}
```

This allows swapping implementations without changing business logic.

##  Configuration

### Feature Flags (Mock)

Set flags in `MockConfigService`:

```dart
_flags['my_feature_enabled'] = true;
```

### Storage Keys

Standard keys used by the template:
- `onboarding_seen`: Boolean, tracks onboarding completion
- More keys will be added in future versions

##  Next Steps

**v0.3 - Configuration & Feature Flags** (Upcoming):
- Remote config with caching
- Flag precedence (defaults → cached → remote)
- Developer overrides
- Build-time environment variables

See `BLUEPRINT.md` for the complete roadmap.

##  Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

##  License

See LICENSE file for details.

##  Troubleshooting

### Router not navigating

Ensure you're using the `NavigationService` from the service locator:

```dart
final nav = ServiceLocator().get<NavigationService>();
nav.goToRoute('home');
```

### Guards not firing

Check that:
1. Guards are registered in `createRouter()`
2. Route IDs match exactly (case-sensitive)
3. Guards are ordered by priority

### Tests failing

Run with verbose output:

```bash
flutter test --reporter expanded
```

Check that mocks are properly set up and return values match expectations.

---


