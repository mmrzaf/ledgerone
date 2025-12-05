
---

### `CHANGELOG.md`

```md
# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and the project follows Semantic Versioning.

---

## [0.8.0] - 2025-12-06

### Theme

Baseline hardened, no-auth line: Onboarding → Home with real infra (config, offline, errors, observability, i18n, theming).

### Added

- **Launch & boot sequence**
  - `main.dart` updated to:
    - Start a cold-start performance metric.
    - Initialize DI (`setupDependencies`) including localization and theme.
    - Resolve `LaunchState` and compute initial route ID.
    - Build router via `RouterFactory.create`.
    - Stop cold-start metric after first frame and log an `app_launch` analytics event.   

- **Navigation stack (baseline line)**
  - `RouterFactory` now owns:
    - Stable route IDs (`onboarding`, `home`).
    - Route-ID → path mapping for go_router.
  - `NavigationServiceImpl` wraps `GoRouter` for UI-agnostic navigation.   
  - `OnboardingGuard` enforces onboarding completion before protected routes.   

- **Onboarding & Home flows**
  - Onboarding screen:
    - Uses localization keys for all copy.
    - Sets `onboarding_seen` on skip/complete and navigates to Home.   
  - Home screen:
    - Orchestrates loading, ready, empty, and error UI states.
    - Uses `HomeRepository` abstraction (remote + local data sources).
    - Supports pull-to-refresh + explicit refresh button.
    - Shows cached data & timestamp when offline.   

- **Offline-first data path**
  - `HomeLocalDataSource` uses `CacheService` with TTL and a persistent index.
  - `HomeRemoteDataSource` wraps `HttpClientService` and maps responses into `HomeData`. It:
    - Handles plain and `{ data: ... }` response shapes.
    - Transliterate parse failures into `AppError(parseError)`.
    - Propagates upstream `AppError`s from the HTTP client.   
  - `HomeRepositoryImpl`:
    - Returns fresh data on success and caches it.
    - Falls back to cached data on failure when available.
    - Returns a timeout error when neither remote nor cache succeeds. :contentReference[oaicite:81]{index=81}  

- **Error handling integration**
  - `ErrorPresenter` + `ErrorCard` wired into Home to:
    - Decide inline vs banner/toast using `ErrorPolicyRegistry`.
    - Show localized messages from i18n keys.
    - Emit `error_shown` and `error_retry` analytics events.   
  - Integration tests covering:
    - Inline error with manual retry.
    - Safe behavior when screen is disposed mid-load.   

- **Network & lifecycle**
  - Network service integrated into Home and offline tests:
    - Online/offline/unknown status with a stream.
    - Simulated implementation for tests.   
  - App lifecycle service used to coordinate resume behavior.   

- **Docs**
  - `BLUEPRINT.md` updated to clearly separate baseline line (v0.1–v0.8) from auth line (v0.9+), with acceptance criteria and risks.   
  - README rewritten to describe v0.8 as a no-auth baseline and to point consumers at the correct tag line.   

### Changed

- Tightened separation between **Core** and **App**:
  - Core holds contracts, policies, and primitives only.
  - All concrete services moved/confirmed under `app/services` or feature data layers.   
- `ConfigServiceImpl` now feeds launch state resolution and Home feature flags, not accessed directly from widgets.   
- Observability:
  - Cold start performance metric added around DI + launch + first frame.
  - Home tests assert correct behavior under retries and offline scenarios.   

### Removed

- Authentication routing and guards are not wired into this line; any auth flow now belongs exclusively to v0.9+ tags as described in the blueprint.   

### Quality

- All unit, widget, and integration tests pass (core errors, retry, cancellation, config, i18n, themes, analytics, launch, network, cache, home flows).   
- `flutter analyze` is clean.  
- Home’s offline and error integration tests cover:
  - Timeout → inline error → retry → success.
  - Disposal while load in flight without `setState` after dispose.   

---

## [0.7.0] - 2025-12-06

### Theme

Accessibility, i18n, and theming: make the app usable for real humans in multiple locales.

### Added

- **Internationalization**
  - `LocalizationServiceImpl` to manage the active locale, translations, and persistence.
  - 3 fully translated locales:
    - English (`en`)
    - German (`de`)
    - Persian/Farsi (`fa`, RTL)   
  - Central `L10nKeys` enum-like class for string keys.
  - Translation coverage for onboarding, login, home, errors, a11y labels, and network state strings.
  - Fallback behavior when keys are missing.

- **RTL support**
  - Automatic text direction based on locale.
  - Layout helpers (`RtlAwareLayout`) for directional padding/alignment.   

- **Theme system**
  - `AppTheme`, `AppColorScheme`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppElevation` defined as design tokens.   
  - Default light and dark themes with semantic color roles (primary, surface, background, error, success, warning, outline, scrim).   
  - `ThemeServiceImpl`:
    - Exposes available themes and current theme.
    - Persists the user’s choice via storage.
    - Provides `toggleBrightness()`.   

- **Accessibility**
  - A11y helpers and widgets:
    - Touch target enforcement.
    - Label generators (`A11yLabels`).
    - Focus and semantics helpers.
    - Text scaling support with clamped min/max.   

### Changed

- `App` widget:
  - Accepts `LocalizationService` and `ThemeService`.
  - Wraps its tree with appropriate `Directionality`.
  - Builds `ThemeData` from `AppTheme` rather than hard-coded `ThemeData`.   

- DI & main:
  - DI now initializes localization and theme services early.
  - `main.dart` passes both into `App`.   

- Component theming:
  - Buttons: 48dp min height, consistent radius.
  - Inputs: unified padding and borders.
  - Cards: low elevation, high-contrast borders.   

### Quality

- i18n tests for locale switching, persistence, interpolation, and fallbacks.
- Theme tests verifying token completeness and correct properties for light/dark themes.   

---

## [0.6.0] - 2025-12-05

### Theme

Offline-first & data resilience: the app should still be useful with a sketchy connection.

### Added

- `NetworkService` with status stream (online/offline/unknown) and a simulated implementation for tests.   
- `CacheServiceImpl`:
  - In-memory + persistent storage with TTL.
  - Index of cache keys for cleanup and inspection. :contentReference[oaicite:105]{index=105}  
- `AppLifecycleService` to react to foreground/background transitions.   
- `OfflineBanner` for showing explicit offline state in the UI.   
- End-to-end tests for:
  - Network status behavior.
  - Cache TTL handling.
  - Offline fallback of feature data.   

---

## [0.5.0] - 2025-12-05

### Theme

Observability & telemetry: know what the app is doing in the wild.

### Added

- Analytics facade with:
  - Allow-listed events and parameter schema (`AnalyticsAllowlist`).
  - Simple consent handling (events blocked when consent is false).
  - Optional vendor integration behind an adapter.   
- Performance metrics:
  - `PerformanceTracker` for start/stop/mark/measure.
  - Standard metrics like `cold_start` and `home_ready`.   
- Crash reporting facade with hooks for breadcrumbs and PII scrubbing (behind an interface; vendor optional).   
- Feature-level analytics for onboarding and home flows (`onboarding_view`, `onboarding_complete`, `onboarding_skip`, `home_view`, `home_refresh`, `home_error`, `error_shown`, `error_retry`).   

### Changed

- Onboarding and Home screens emit structured telemetry aligned with the allow-list.   

---

## [0.4.0] - 2025-12-04

### Theme

Error policy & resilience: predictable failures, retries, and safe cancellation.

### Added

- `ErrorPolicyRegistry` mapping each `ErrorCategory` to:
  - Presentation mode (inline/banner/toast/silent).
  - Retry strategy (never/manual/automatic) with caps and delays.
  - Localized message key.   
- `ErrorPresenter` and `ErrorCard` for consistent error rendering and analytics logging.   
- `RetryHelper`:
  - Policy-aware retries.
  - Exponential backoff with jitter.
  - Cancellation-aware delays.   
- `CancellationToken`, `CancellationTokenSource`, `OperationCancelledException` primitives plus full unit test coverage.   

### Changed

- Feature flows (login and home at the time) moved to:
  - Use `RetryHelper` for network calls.
  - Respect cancellation when navigating away mid-operation.
  - Render errors via centralized policies instead of ad-hoc handling.   

---

## [0.3.0] - 2025-11-20

### Theme

Configuration & feature flags.

### Added

- `ConfigService` with precedence:
  - Defaults → cached → remote. :contentReference[oaicite:119]{index=119}  
- Simulated remote config provider for local development.   
- Background refresh of flags without blocking startup.
- Example flags:
  - `onboarding.enabled`
  - `home.promo_banner.enabled` (used by Home).   
- Tests covering precedence, caching, and startup behavior.

---

## [0.2.0] - 2024-11-18

### Theme

Navigation & routing foundation.

### Added

- Route registry and manifest-driven routing concept.
- `NavigationService` contract to decouple UI from router choice.
- GoRouter integration with guard support.
- Launch state machine:
  - Initializes config.
  - Reads onboarding state.
  - Computes initial route.   
- Screens:
  - Onboarding (complete/skip).
  - Login.
  - Home.
- Mock services for config, storage, auth, analytics, and crash reporting.   

### Testing

- Guard tests with complete coverage of flows and priority ordering.
- Launch state tests for all startup branches.
- Integration tests for main navigation paths (Onboarding → Home, Login, Logout).   

---

## [0.1.0] - 2024-11-10

### Theme

Skeleton & contracts.

### Added

- Project layout and initial build setup.
- Empty feature shells for Onboarding and Home.
- Initial Core contracts for config, navigation, and error handling.
- Basic error taxonomy and `Result<T>` helper.
- Test harness with `flutter_test` and mocktail.   

### Quality

- Lints and formatting in place.
- App builds and shows a placeholder screen.
- First ADRs for routing, DI, and project structure captured in docs.

