# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-11-18

### Added

#### Navigation & Routing Foundation
- **Route Registry**: Dynamic route assembly from feature manifests
- **Navigation Service Contract**: UI-agnostic navigation abstraction (`NavigationService`)
- **GoRouter Integration**: Production-ready router with guard support
- **Guard System**: 
  - `NavigationGuard` contract with priority-based execution
  - `OnboardingGuard`: Blocks routes until onboarding is complete
  - `AuthGuard`: Requires valid authentication, attempts silent refresh
  - `NoAuthGuard`: Redirects authenticated users away from login
  - Guards execute in deterministic order: Onboarding (0) → Auth (10) → NoAuth (20)

#### Launch State Machine
- **LaunchState**: Encapsulates app state at boot (onboarding, auth, deep links)
- **LaunchStateResolver**: Orchestrates startup sequence
  1. Initialize configuration (cached first)
  2. Check onboarding status
  3. Validate/refresh authentication
  4. Determine initial route
- **Boot Sequence**: Clean separation of DI setup, state resolution, and router creation

#### Feature Screens
- **OnboardingScreen**: Complete/Skip functionality with navigation
- **LoginScreen**: Email/password validation, error handling, loading states
- **HomeScreen**: Welcome screen with logout functionality
- All screens follow dependency injection pattern via constructor

#### Service Layer
- **Mock Services**: In-memory implementations for v0.2 testing
  - `MockConfigService`: Feature flag management
  - `MockStorageService`: Key-value persistence
  - `MockAuthService`: Authentication lifecycle
  - `MockAnalyticsService`: Event tracking
  - `MockCrashService`: Error reporting
- **Service Locator**: Simple DI container for v0.2 (ready for production DI in later versions)

#### Testing
- **Guard Tests**: 100% coverage of all guard logic and priorities
- **Launch State Tests**: Complete state machine scenarios
- **Integration Tests**: End-to-end navigation flows
  - Fresh install → Onboarding → Home
  - Skip onboarding → Login
  - Invalid/valid credentials
  - Authenticated user redirect
  - Logout flow
  - Guard priority ordering

### Changed
- **Feature Manifests**: Now include guard requirements and deep link matchers
- **App Structure**: Root app widget now uses `MaterialApp.router`
- **Main Entry**: Implements 4-phase boot sequence

### Dependencies
- Added `go_router: ^14.6.2`

### Documentation
- Updated README with v0.2 setup instructions
- Added ADRs for navigation architecture decisions
- Comprehensive inline code documentation

### Quality Gates ✅
- ✅ Navigation unit tests achieve >70% coverage
- ✅ All guarded routes correctly block/allow access
- ✅ Integration tests cover critical user flows
- ✅ Startup sequence makes ≤2 async calls (config + auth check)
- ✅ Guard order is deterministic and testable
- ✅ Deep link structure is defined (implementation in later versions)

### Migration Notes
- Update `pubspec.yaml` to include `go_router` dependency
- Run `flutter pub get`
- The launch state machine expects storage keys: `onboarding_seen`
- Guards are stateless and safe to recreate on each navigation

### Known Limitations
- Deep link handling is stubbed (full implementation in v0.3+)
- Service implementations are in-memory only
- No production DI framework yet (planned for v0.3+)

---

## [0.1.0] - 2024-11-15

### Added
- Initial project structure and contracts
- Core error taxonomy (`AppError`, `Result<T>`)
- Service contracts: Auth, Config, Storage, Analytics, Crash, HttpClient
- Feature manifests: Onboarding, Auth, Home
- Empty feature shells
- ADR template and initial architecture decisions
- Linting and formatting configuration
- Basic unit tests for error types

### Quality Gates ✅
- ✅ Linting and formatting pass
- ✅ Initial test harness executes
- ✅ Build produces runnable empty application
