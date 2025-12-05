# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0] - 2025-12-05

### Theme
Offline-First & Data Resilience: Still useful with a bad connection.

### Added
- **NetworkService**: Monitors device connectivity status (online/offline/unknown)
  - Stream-based status updates
  - Mock implementation for v0.6 (ready for connectivity_plus integration)
- **CacheService**: Data caching with TTL support
  - In-memory + persistent storage
  - Last-known-good strategy for offline resilience
  - Stale data detection and age tracking
- **AppLifecycleService**: Monitors app foreground/background transitions
  - Callbacks for app resume/pause events
  - Time tracking for background duration
- **OfflineBanner**: Visual indicator when network is unavailable
  - Non-blocking banner UI
  - Integrates with OfflineAwareScaffold wrapper
- **Home Screen Offline Support**:
  - Last-known-good caching: displays cached data when offline
  - Background refresh on app resume (with backpressure)
  - Minimum refresh interval (1 minute) to prevent excessive requests
  - Cached data indicator when showing stale content
  - Network-aware retry behavior

### Changed
- **Home Screen**
  - Now requires NetworkService, CacheService, and AppLifecycleService dependencies
  - Loads from cache first, then fetches fresh data
  - Shows cached data with warning indicator if refresh fails
  - Automatically refreshes on app resume (respects backpressure rules)
- **DI Setup**
  - Registers network, cache, and lifecycle services
  - Updated router factory to pass new dependencies to screens
- **Router Factory**
  - Accepts network, cache, and lifecycle services
  - Provides them to route screens

### Fixed
- Home screen now gracefully handles offline scenarios
- No infinite retry loops - respects network status
- Background refresh doesn't spam requests (1-minute minimum interval)

### Quality Gates ✅
- ✅ Key paths (Home) functional in airplane mode with cached data
- ✅ Retry ceilings honored - no infinite retries
- ✅ Network status monitoring works correctly
- ✅ Cache TTL and staleness detection accurate
- ✅ Background refresh respects backpressure (1-minute minimum)

### Notes
- This is the "v0.6 – Offline-First & Data Resilience" milestone from the blueprint:
  - NetworkStatus abstraction provides online/offline detection
  - Last-known-good strategy shows cached data when network fails
  - Foreground refresh with backpressure prevents request storms
  - Visual offline indicator (banner) informs users of connection status
- For production use:
  - Replace SimulatedNetworkService with connectivity_plus integration
  - Implement proper cache serialization for complex types
  - Add cache eviction policies for memory management

## [0.5.0] - 2025-12-05
### Added
- Observability & Telemetry milestone:
  - Analytics facade with allow-listed events and consent handling.
  - Performance metrics for cold start and home readiness.
  - Crash reporting facade with breadcrumbs and PII scrubbing.
  - CI guard ensuring only allow-listed analytics events are used.
  - Feature-level analytics for onboarding and home flows (`onboarding_view`, `onboarding_complete`, `onboarding_skip`, `home_view`, `home_refresh`, `home_error`, `error_shown`, `error_retry`).

### Changed
- Home and onboarding screens now emit structured telemetry aligned with the analytics schema.

## [0.4.0] - 2025-12-04

### Theme
Error policy & resilience: predictable failures, retries, and safe cancellation.

### Added
- Central `ErrorPolicyRegistry` that maps every `ErrorCategory` to a concrete policy:
  - Presentation mode (inline, banner, toast, silent).
  - Retry strategy (never, manual, automatic) and retry caps. 
- `ErrorPresenter` + inline `ErrorCard` widget to render errors according to policy, including banner/toast flows. 
- `RetryHelper` with:
  - Policy-based retries (`executeWithPolicy`).
  - Exponential backoff with jitter.
  - Cancellation-aware delay. 
- `CancellationToken`, `CancellationTokenSource`, and `OperationCancelledException` primitives, plus unit tests for all core cancellation behaviors. 
- Comprehensive tests for the error taxonomy and error policies (all categories covered, policy invariants asserted). 
- Integration tests for error flows:
  - Login: failure, retry, navigation-away safety.
  - Home: load, retry, and non-crash behavior under simulated failures. 

### Changed
- **Login screen**
  - Uses `CancellationTokenSource` tied to the widget lifecycle; token is disposed in `dispose()`.   
  - Throws on cancellation before navigation and gracefully ignores `OperationCancelledException` so navigation-away during an in-flight login doesn’t explode the UI.
- **Home screen**
  - Initial load and refresh now go through `RetryHelper.executeWithPolicy` with a cancellation token, so retries and delays respect cancellation and centralized error policy.   
  - UI is explicit about `loading / empty / error / ready` states and uses `ErrorCard`, `LoadingIndicator`, and `EmptyState` building blocks. 

### Fixed
- Guard / navigation tests updated to assert deterministic guard order (`OnboardingGuard`, `AuthGuard`, `NoAuthGuard`) and correct redirects. 
- Retry helper edge cases:
  - Correct attempt counting.
  - Respect for `never` retry strategy.
  - Proper wrapping of non-`AppError` exceptions as `AppError(unknown)`. 

### Notes
- This is the “v0.4 – Error Policy & Resilience” milestone from the blueprint:
  - Error→policy mapping is now the single source of truth.
  - Cancellation is wired from UI to retry/cancellation primitives.
  - Navigation-away scenarios are covered by tests (login + home). 

## [0.3.0] - 2025-11-20

### Added
#### Configuration & Feature Flags
- **ConfigService**: Implements 3-layer precedence (Defaults → Cache → Remote).
- **Background Refresh**: Config updates happen asynchronously without blocking boot.
- **Caching Strategy**: Last-known flags persist across restarts.
- **Simulated Remote Config**: Logic for fetching remote flags (ready for vendor integration).
- **Feature Gating**: UI (Home Screen) adapts based on `home.promo_banner.enabled` flag.

### Quality Gates ✅
- ✅ App boots offline using cached configuration.
- ✅ Startup sequence executes ≤2 remote calls.
- ✅ Config precedence tests pass (Cache > Default).
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
