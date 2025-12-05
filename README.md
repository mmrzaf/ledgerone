# Flutter Starter Template

A structure-first Flutter starter focused on one thing: a production-ready baseline without authentication.  
You get a clean Onboarding → Home flow, offline-aware data loading, predictable error handling, i18n, theming, and observability, all wired through clear interfaces.

If you need sign-in / auth flows, use the auth line (v0.9+) instead of trying to bolt it onto 0.8

---

## What this template gives you

**App behavior**

- Onboarding → Home as the only user flow.
- Launch state machine deciding whether to show Onboarding or go straight to Home.
- Home screen with proper **loading / ready / empty / error** states and manual refresh.
- Offline banner and “last known good data” fallback when the network is flaky.   

**Infra & architecture**

- Dependency setup in a single composition root (`app/di.dart`) with a simple service locator.
- Core contracts under `lib/core/contracts` for config, storage, network, cache, localization, theme, analytics, and more.
- Launch state resolution and router creation separated from widgets.   
- Error taxonomy, error policies, retry helper, and cancellation tokens for predictable failure behavior.   

**UX, i18n & theming**

- 3 locales:  
  - English (`en`) – LTR  
  - German (`de`) – LTR  
  - Persian/Farsi (`fa`) – RTL   
- RTL-aware layout helpers and directionally correct padding/alignment.
- Design tokens (`AppColorScheme`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppElevation`) and a theme service supporting light/dark themes with persistence.   
- Accessibility helpers for touch targets, labels, announcements and semantic wrappers.   

**Observability**

- Analytics facade with an allow-listed event set (`AnalyticsAllowlist`).   
- Performance tracker that measures cold start, DI, launch resolution, and home readiness.   
- Optional analytics vendor, PII-scrubbing of event parameters, and hashed user IDs.

**Testing**

- Unit tests for error taxonomy, error policies, retry logic, cancellation, config precedence, i18n, themes, analytics, and launch state.   
- Widget tests for error rendering and a11y building blocks.   
- Integration tests for offline behavior and home screen error flows.   

---

## When to use this tag

Use **v0.8.0** if:

- Your app **does not require authentication**, now or ever.
- You want a hardened baseline with:
  - One clear user flow;
  - Production-grade infra for config, caching, error handling, and telemetry;
  - Minimal business logic you’ll throw away later.
- You want to plug in your own backend, monitoring, and feature modules without fighting the template.

If you know you’ll need auth from day one (login, sessions, token refresh, auth-gated routes), plan to start from the auth line (v0.9+) described in `BLUEPRINT.md`.   

---

## Getting started

### Requirements

- Flutter `3.9.x` (or newer 3.x compatible with Dart 3).  
- Dart `>=3.0.0`.  
- A recent `flutter` SDK on your PATH.

### Clone & run

```bash
git clone <your-fork-url> app_flutter_starter
cd app_flutter_starter

flutter pub get
flutter test
flutter run
````

By default the app boots in **dev** environment via:

```dart
const config = AppConfig.dev; // in main.dart
```

Point it at your own environments by editing `core/config/environment.dart`.

---

## Project structure

High level layout:

```text
lib/
  core/        # Contracts, primitives, policies (no feature code)
  app/         # Composition root: DI, boot, router, services, app widget
  features/
    onboarding/
    home/
  shared/      # Reusable UI/components

test/
  core/        # Core contracts & policies
  app/         # Boot, routing, DI
  features/    # Feature tests
  integration/ # Cross-cutting flows (offline, error handling, etc.)

docs/
  BLUEPRINT.md # Version lines & roadmap
```

### Core (lib/core)

Core owns:

* **Contracts** (`config`, `storage`, `network`, `cache`, `i18n`, `theme`, `analytics`, `lifecycle`).
* **Error taxonomy** (`AppError`, `ErrorCategory`, `Result<T>`).
* **Error policy** (`ErrorPolicyRegistry`, `ErrorPresentation`, `RetryStrategy`).
* **Runtime primitives**: `CancellationToken`, `CancellationTokenSource`.
* **Observability**: `PerformanceTracker`, analytics allow-list & typed events.
* **i18n**: `L10nKeys`, translation maps for `en`, `de`, `fa`.
* **Design tokens**: `AppColorScheme`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppElevation`.

Core never imports feature modules or app wiring.

### App (lib/app)

App layer wires Core into a real Flutter app:

* `app/di.dart`: builds the `ServiceLocator` and registers all implementations (config, storage, network, cache, lifecycle, localization, theme, analytics, crash).
* `app/boot/launch_state_machine.dart`: resolves `LaunchState` (onboardingSeen, flags) and decides the initial route ID.
* `app/navigation/router.dart`: creates a `GoRouter` from route IDs and attaches guards. 
* `app/navigation/navigation_service.dart`: UI-agnostic API for navigation from widgets. 
* `app/services/*.dart`: concrete implementations (config, cache, network, i18n, theme, analytics, lifecycle).
* `app/presentation/error_presenter.dart`: bridges `AppError` + `ErrorPolicyRegistry` to snackbars/toasts/inline error cards.
* `app/app.dart`: top-level `App` widget that wires router, localization, theme, and text scaling limits into `MaterialApp.router`.

The `main.dart` file orchestrates the boot sequence in four phases, tracks cold start metrics, and logs an analytics event once the first frame is rendered.

### Features (lib/features)

* `features/onboarding`:

  * Simple screen with title, copy, “Get started”, and “Skip” actions.
  * Persists `onboarding_seen` in storage and then navigates to `home`.

* `features/home`:

  * Uses a `HomeRepository` abstraction built on `HomeRemoteDataSource` + `HomeLocalDataSource`.
  * Loads data with retry semantics and error policies.
  * Shows offline banner, inline error card, cached content, and timestamps.

Each feature only depends on Core contracts, not on app wiring or other features.

---

## Navigation & routing

Routing is centered around **route IDs** rather than hard-coded paths.

### RouterFactory & NavigationService

* `RouterFactory.create` builds a `GoRouter` from:

  * A map of route IDs to paths (e.g. `'home' -> '/home'`).
  * Guard list (e.g. `OnboardingGuard`).
* `NavigationService` exposes methods like:

  * `goToRoute(String routeId, {Map<String, String>? params})`
  * `replaceWith(String routeId, {Map<String, String>? params})`
  * `pop<T extends Object?>([T? result])` 

Typical usage from UI:

```dart
final nav = ServiceLocator().get<NavigationService>();
nav.goToRoute('home');
```

### Guards

For this tag there is a single guard: **OnboardingGuard**.

* If `onboardingSeen == false` and the target route requires onboarding:

  * User is redirected to Onboarding.
  * After completing/skipping, the original target is retried.

Auth-related guards (`requiresAuth`, `requiresNoAuth`) only appear in the auth line (v0.9+) and are not wired into this template.

---

## Configuration & feature flags

Config is provided by a **ConfigService** implementation in `app/services/config_service_impl.dart` plus a simulated remote config source.

Key ideas:

* Multiple layers with clear precedence:

  1. Built-in defaults (`defaultFlags`). 
  2. Cached remote values.
  3. Fresh remote fetch at runtime.
* Access via type-safe getters:

  * `getBool`, `getString`, `getInt`, etc.
* Consumers (features, app) never read raw environment variables or platform APIs; everything flows through `ConfigService`.

Example (pseudo):

```dart
final config = ServiceLocator().get<ConfigService>();
final onboardingEnabled = config.getBool('onboarding.enabled', defaultValue: true);
```

On startup, config is read as part of the launch state resolution, not directly in widgets.

---

## Offline, errors & retries

The template assumes your backend, network, and user devices will misbehave.

### Caching

* `CacheServiceImpl` provides in-memory + persistent caching with TTL and a central index for keys. 
* `CachedData<T>` stores data, cache time, TTL, and `isValid` status.
* Home feature uses this to show last known good content when fresh loads fail.

### Network status & lifecycle

* `NetworkService` tracks online/offline/unknown with a status stream.
* `AppLifecycleService` exposes foreground/background transitions; the Home screen can refresh data when returning from background if needed.

### Error taxonomy & policy

* Errors are represented by `AppError` with an `ErrorCategory`.
* `ErrorPolicyRegistry` is the **single source of truth** for:

  * How to show the error (inline, banner, toast, silent).
  * Whether to retry (never/manual/automatic).
  * Retry caps and delays.
  * The user-facing message key (`error.*`).

### Retry & cancellation

* `RetryHelper.execute` and `executeWithPolicy` apply capped exponential backoff and consult `ErrorPolicyRegistry`.
* `CancellationToken` allows UI to cancel long-running operations when screens are disposed or navigated away from.

### Presenting errors

* `ErrorPresenter`:

  * Resolves a policy for a given `AppError`.
  * Emits snackbars or toasts (with analytics events) for banner/toast policies.
  * Leaves inline rendering to UI widgets.

* `ErrorCard`:

  * Inline error block with localized title, error message, optional retry button, and dismiss.
  * Logs an `error_shown` event via analytics allow-list.

---

## Localization, accessibility & theming

### i18n

* String keys live in `L10nKeys`.
* Translations are defined per locale in `core/i18n/translations.dart`.
* `LocalizationServiceImpl` manages:

  * Active locale.
  * Loading translation maps.
  * Persistence to storage.

Use in widgets via extension:

```dart
final l10n = context.l10n;
Text(l10n.get(L10nKeys.homeTitle));
```

### RTL & layout

* `RtlAwareLayout` provides directional padding and alignment helpers. 
* Choosing the Persian locale (`fa`) switches the app into RTL mode automatically.

### Theme & design tokens

* `ThemeServiceImpl`:

  * Loads default theme (light).
  * Persists selected theme to storage.
  * Exposes `availableThemes`, `currentTheme`, and `toggleBrightness()`.

* `AppTheme`, `AppColorScheme`, and `AppTypography` define semantic colors and typography, then `App` builds a `ThemeData` from them.

* Component themes:

  * Buttons with 48dp min height.
  * Inputs and cards styled with consistent radii and borders.
  * Icons aligned to semantic colors.

### Accessibility

* Helpers:

  * `A11yGuidelines` and `AccessibleTouchTarget` enforce minimum touch area.
  * `A11yLabels` for semantic strings.
  * Extensions like `.withLabel()`, `.asHeader()`, `.excludeFromSemantics()`.

The template aims for WCAG AA-friendly defaults (contrast, touch targets, text scaling), not pixel-perfect design.

---

## Observability

* `AnalyticsAllowlist` defines events like:

  * `app_launch`, `onboarding_view`, `onboarding_complete`, `onboarding_skip`,
  * `home_view`, `home_refresh`, `home_error`, `error_shown`, `error_retry`.
* `AnalyticsServiceImpl`:

  * Rejects events not in the allow-list.
  * Validates and sanitizes parameters.
  * Can forward to a vendor SDK, if configured.
* `PerformanceTracker`:

  * Tracks durations for named metrics like `cold_start` and `home_ready`.
  * Stores multiple measurements per metric and supports metadata (e.g. env, result).

Cold start is measured in `main.dart` and an `app_launch` analytics event is emitted once the UI has rendered.

---

## Testing

Run the full suite:

```bash
flutter test
```

Useful patterns:

* Integration tests under `test/integration` exercise:

  * Network service behavior.
  * Offline cache behavior.
  * Error handling on the Home screen.
* Core tests assert invariants:

  * Every `ErrorCategory` has a policy.
  * Retry strategies respect policies.
  * Cancellation tokens behave as expected.
  * Analytics metrics and events are well-formed.

If tests fail, start by running:

```bash
flutter test --reporter expanded
```

and inspect any broken assumptions in mocks or policies. 

---

## Adapting this template to your app

Practical order of operations:

1. **Rename the app**

   * Update `pubspec.yaml` (name, description). 
   * Update bundle identifiers / package names as needed.

2. **Wire your environments**

   * Edit `AppConfig` enum (`core/config/environment.dart`).
   * Set API base URLs and build-time env vars for dev/stage/prod.

3. **Plug in your backend**

   * Replace `HttpClientService` implementation and the Home data sources with your real API calls.
   * Preserve the error taxonomy and wrap backend failures as `AppError`.

4. **Change the UX**

   * Rewrite Onboarding and Home copy/visuals.
   * Add features in `features/<name>` with their own domain, data, and UI slices.

5. **Add routes**

   * Extend router config in `RouterFactory` with new route IDs and paths.
   * Use `NavigationService` everywhere instead of pushing routes directly.

6. **Extend analytics**

   * Add new events to the allow-list + tests.
   * Emit them from your feature code via `AnalyticsService`.

7. **Keep Core lean**

   * Add new contracts to Core only when multiple features would depend on them.
   * Put concrete implementations in `app/services` or feature data layers.

---

## Version lines & roadmap

The full roadmap and the split between **baseline line (v0.1–v0.8)** and **auth line (v0.9+)** live in `docs/BLUEPRINT.md`. That file also spells out acceptance criteria, risks, and CI expectations for each milestone.

---

## License

This starter is released under the license described in `LICENSE`.
Check that file before using it in a commercial codebase.

