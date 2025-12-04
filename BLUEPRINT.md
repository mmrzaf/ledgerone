# Flutter Starter Template — Project Blueprint (v0.1 → v0.9)

> **Purpose**
> A reusable, UI-agnostic Flutter project skeleton you can fork for new apps. It prioritizes **structure, stability, scalability, security, and efficiency**, so you can focus on features—not plumbing.
>
> The template evolves in two **version lines**:
>
> * **v0.1 → v0.8**: hardened **baseline without authentication** (Onboarding → Home).
> * **v0.9+**: same baseline, extended with **authentication** (Onboarding → Login → Home, email+password only).
>
> Consumers pick a **tag**:
>
> * Use **v0.8** as the base for apps that will **never** need auth.
> * Use **v0.9+** for apps that **require auth**.
>   There is no runtime flag to “turn auth off” in the auth line; that’s a version choice. 

---

## Table of Contents

1. [Scope & Principles](#scope--principles)
2. [Targets & Assumptions](#targets--assumptions)
3. [Project Structure](#project-structure)
4. [Layering & Dependency Rules](#layering--dependency-rules)
5. [Feature Modules](#feature-modules)
6. [Navigation & Guards](#navigation--guards)
7. [Configuration & Flags](#configuration--flags)
8. [Security & Privacy](#security--privacy)
9. [Performance Requirements](#performance-requirements)
10. [Offline & Resilience](#offline--resilience)
11. [Observability (Analytics, Perf, Crash)](#observability-analytics-perf-crash)
12. [Accessibility & Internationalization](#accessibility--internationalization)
13. [Theming & UI Abstraction](#theming--ui-abstraction)
14. [Error Taxonomy & Display Policy](#error-taxonomy--display-policy)
15. [Testing Strategy](#testing-strategy)
16. [CI/CD Gates](#cicd-gates)
17. [Release Plan (v0.1 → v0.9)](#release-plan-v01--v09)
18. [Operational Playbooks](#operational-playbooks)
19. [MVP Acceptance Criteria](#mvp-acceptance-criteria)
20. [Risks & Mitigations](#risks--mitigations)
21. [Glossary](#glossary)

---

## Scope & Principles

**Scope**

* The starter covers **two version lines**:

  * **Baseline (v0.1 → v0.8)**

    * No authentication at all.
    * Core screens: **Onboarding → Home**.
  * **Auth line (v0.9+)**

    * Adds authentication on top of the baseline.
    * Auth is **email + password only** (no signup, no forgot, no OAuth).
    * Screens: **Onboarding → Login → Home**.
* Template is **UI/theme agnostic**; any design system can be swapped in later without touching business logic.

**Principles**

* **Stable**: minimal global state; explicit contracts; predictable boot sequence.
* **Scalable**: vertical feature modules; interfaces in Core; implementations swappable.
* **Secure**: least privilege; secure storage (auth line); redacted logs; safe-by-default behaviors.
* **Efficient**: fast cold start; lazy work; cancellable I/O; capped retries.
* **Clear**: decisions documented; tests cover flows, contracts, and failure modes.
* **Version-explicit**: baseline and auth are separated by **tags**, not config switches.

---

## Targets & Assumptions

* Flutter stable, Dart 3+.
* Platforms:

  * Android
  * iOS
  * Web (web auth only if backend supports it in v0.9+).
* No vendor lock-in:

  * HTTP client, DI, router, analytics, crash reporter etc. are **behind interfaces**.

---

## Project Structure

```text
app/              # Composition root (DI wiring, route assembly, app lifecycle)

core/             # Interfaces, primitives, cross-cutting concerns (no feature logic)
  contracts/      # Service interfaces (ConfigService, NavService, AuthService[v0.9+], etc.)
  errors/         # Error taxonomy, result types, error→policy mapping
  policy/         # Security, logging, telemetry allow-list
  runtime/        # Clock, UUID, cancellation token, network status abstractions
  config/         # Flag/env access abstraction
  storage/        # UserPrefs interfaces; SessionStore appears in v0.9+ (auth)
  network/        # HttpClient abstraction, interceptor contracts
  # core/auth/    # Added in v0.9+: auth-related shared contracts & types

features/
  onboarding/     # ui/, logic/, domain/ (use cases), data/ (mappers/repos if any)
  home/           # ui/, logic/, (optional) data/
  # auth/         # Added in v0.9+: ui/, logic/, domain/, data/ (login only)

shared/           # Optional: a11y helpers, simple UI primitives; no business logic
assets/           # i18n placeholders, images (optional)
test/             # unit/, widget/, integration/ (mirrors src)
docs/             # ADRs, playbooks, release notes, security notes
tool/             # CI configs, scripts (no secrets)
```

**Version specifics**

* **v0.1 → v0.8**: only `onboarding/` and `home/` features exist; no auth contracts or auth feature code.
* **v0.9+**: `core/auth/`, `features/auth/`, and auth-specific wiring in `app/` are introduced.

**Rules**

* Features **do not** import each other. They depend only on **Core contracts**.
* **App** composes DI bindings and the route table.
* **Core** contains **interfaces + primitives + policies only** (no feature business logic).

---

## Layering & Dependency Rules

* Stack:

  * **UI** ↔ **Feature Logic (state)** ↔ **Use Cases** ↔ **Repositories** ↔ **Data Sources**

* **Contracts live in Core**:

  * `ConfigService`, `NavService`, `ErrorHandler`, `NetworkClient`, `Storage`, `AuthService` (auth line), etc.

* **Concrete implementations** live outside Core:

  * In `app/` (global services) or `features/*/data/` (feature-specific).

* DI binds **interface → implementation** once at startup.

* Cross-cutting policies (security, logging, telemetry, error) live in Core and are **consumed** uniformly.

---

## Feature Modules

Each feature supplies a **Manifest** and follows the same contract pattern.

### Manifest (per feature)

* **Routes it owns**: route IDs (strings), path patterns, deep link targets.
* **Guards required**:

  * Baseline: `requiresOnboarding`.
  * Auth line: `requiresOnboarding`, `requiresAuth`, `requiresNoAuth`.
* **Public events**: analytics event names/properties emitted by the feature.
* **Dependencies requested**: Core interfaces only.
* **State surface**: inputs, outputs, events (UI-agnostic description).

### Onboarding (requirements)

* **Applies to:** baseline (v0.1+) and auth line (v0.9+).

* **Purpose**

  * Present first-run guidance and minimal setup.
  * Mark the user as “onboarded”.

* **State**

  * Current step index.
  * Boolean `onboardingSeen`.

* **Outputs**

  * `onboardingSeen = true` on **Complete** or **Skip**.

* **Routing**

  * **Baseline (≤ v0.8)**:

    * On complete/skip → **Home**.
  * **Auth line (v0.9+)**:

    * On complete/skip:

      * If a valid session exists → **Home**.
      * Else → **Login**.

* **Constraints**

  * No OS permission prompts here (notifications, location, etc.). Those are requested later within specific features.

* **Analytics**

  * `onboarding_view`
  * `onboarding_complete`
  * `onboarding_skip`

### Login (email/password only, v0.9+)

* **Applies to:** auth line only, starting v0.9.

* **Inputs**

  * `identifier` (email or username)
  * `password`

* **Validation**

  * Minimal local validation:

    * Email format (if using email).
    * Non-empty password.
  * Submit button disabled until form is valid.

* **Operations**

  * `login(identifier, password)`:

    * Calls `AuthService.login()`.
    * Persists session on success (`SessionStore` in secure storage).
  * `logout()`:

    * Clears session.
    * Routes back to **Login** (and potentially Onboarding again, depending on strategy).

* **Errors**

  * Neutral messages (do not reveal whether an email exists).
  * Clear differentiation between validation errors and server errors.

* **Routing**

  * On success:

    * If invoked from a guarded deep link:

      * Re-run guards and navigate to the originally requested route.
    * Otherwise → **Home**.
  * On logout:

    * Redirect to **Login** (optionally via Onboarding if you decide to re-show it).

* **Analytics**

  * `login_view`
  * `login_attempt`
  * `login_success`
  * `login_failure` (with reason category, not raw error text)

### Home

* **Applies to:** baseline and auth line.

* **States**

  * `loading`
  * `ready`
  * `empty`
  * `error` (inline, retryable)

* **Behavior**

  * Supports:

    * Initial load.
    * Manual refresh (e.g. pull-to-refresh).
    * Optional background refresh when app returns to foreground.
  * **Baseline:** always accessible (no auth guards).
  * **Auth line:** can be protected via `requiresAuth` guard.

* **Analytics**

  * `home_view`
  * `home_refresh`
  * `home_error`

---

## Navigation & Guards

**Route IDs**

* Route IDs are string constants owned by features.
* Deep link paths map to route IDs in the app layer.

**Guard Types (defined in App)**

* **Baseline (≤ v0.8)**

  * `requiresOnboarding`

    * Blocks access until `onboardingSeen = true`.
    * If not seen: redirect to Onboarding, then resume intended route after complete/skip.

* **Auth line (v0.9+)**
  In addition to `requiresOnboarding`:

  * `requiresAuth`

    * If no valid session: redirect to Login.
    * After login, re-evaluate guards and proceed to target route.

  * `requiresNoAuth`

    * If already authenticated: redirect away from Login (e.g. to Home).

**Guard Behavior**

* Evaluation order is fixed:

  1. `requiresOnboarding`
  2. `requiresAuth` (auth line only)
  3. `requiresNoAuth` (auth line only)
* Deep links:

  * Routed through the same guard chain.
  * If blocked, user is redirected (Onboarding / Login) and the original intent is retried when conditions are satisfied.

**Initial Route Decision (App launch state machine)**

* **Baseline (v0.1 → v0.8)**

  1. Load flags/env (cached first, from `ConfigService`).
  2. Read `onboardingSeen` from storage.
  3. Decision:

     * If `onboarding.enabled == true` and `onboardingSeen == false`:

       * Initial route = **Onboarding**.
     * Else:

       * Initial route = **Home**.
  4. Home then manages its own data loading.

* **Auth line (v0.9+)**

  1. Load flags/env (cached first).
  2. Read `onboardingSeen`.
  3. If onboarding enabled and not seen:

     * Initial route = **Onboarding**.
  4. Otherwise:

     * Try to restore session from `SessionStore` and (optionally) perform silent token refresh.
     * If a valid session exists:

       * Initial route = **Home**.
     * If no valid session:

       * Initial route = **Login**.

---

## Configuration & Flags

**Sources & Precedence**

1. Built-in defaults (bundled with app).
2. Cached remote flags/config.
3. Fresh remote config (fetched at runtime).
4. Developer overrides (dev-only).

**Caching**

* Cache last-known remote config.
* Define TTL, per key or per bundle.
* On cold start:

  * Use cached values immediately.
  * Refresh asynchronously and update in-memory config.

**Access**

* Single **ConfigService** in Core:

  * `getBool`, `getString`, `getInt`, etc.
* Features and app layer never directly read platform env or dart `const` env; they go through `ConfigService`.

**Representative keys (examples)**

* Baseline & auth line:

  * `onboarding.enabled` (bool)
  * `telemetry.enabled` (bool)
  * `home.layout` (string/enum)
  * `theme.tokens.enabled` (bool)
* Auth line only (v0.9+):

  * `auth.login_endpoint`
  * `auth.token_ttl_seconds`
  * `auth.refresh_endpoint`
* **Not present**: a toggle like `auth.enabled`.
  Auth vs no-auth is decided by choosing the correct **tag** (v0.8 vs v0.9+), not by config.

**Build-time keys (compile-time)**

* `APP_ENV` (e.g., `dev`, `stage`, `prod`)
* `API_BASE_URL` (shared or per-feature base URLs)

---

## Security & Privacy

### Baseline (≤ v0.8)

* No user credentials or tokens.
* Focus on:

  * HTTPS only.
  * No PII in logs or analytics events.
  * Minimal, redacted logging of errors.

### Auth line (v0.9+ additions)

* **Credentials & session**

  * Tokens stored only in secure platform storage (Keychain/Keystore equivalents).
  * `SessionStore` abstraction centralizes access.

* **Networking**

  * Auth header injection via HTTP interceptors controlled by `AuthService`.
  * Optional certificate pinning (document policy if used).

* **Token refresh**

  * Single-flight: only one refresh attempt at a time.
  * Capped exponential backoff with jitter on repeated failures.

* **Logging**

  * All secrets (tokens, passwords, keys) are redacted.
  * Debug logs disabled in release builds by default.

* **Clipboard & screenshots**

  * Password fields do not leak values to clipboard by default.
  * Screenshot restrictions for sensitive screens are configurable per app.

* **Crash reporting & analytics**

  * Behind user consent and environment flags.
  * No PII or secrets in crash reports or analytics.

---

## Performance Requirements

* **Cold start**

  * Target ≤ **1.5s** on mid-range Android in release builds.
  * Separate, looser budgets for debug.

* **Startup network**

  * Baseline: typically config fetch only.
  * Auth line: at most **2 calls**:

    * Config/flags.
    * Optional silent session refresh.

* **Home first content**

  * Aim for ≤ **500ms** after initial route is decided.

* **I/O behavior**

  * All network operations cancellable.
  * Retries use capped exponential backoff with jitter.
  * Avoid heavy work on the main isolate at startup.

* **Memory**

  * Avoid large singletons.
  * Prefer lazy initialization of heavy services.

---

## Offline & Resilience

* `NetworkStatus` abstraction (online/offline/unknown).
* Offline UI:

  * Banner or inline messaging on Home when offline.
* **Baseline**

  * Last-known-good Home data where feasible.
  * Read-through caching for stable data.
* **Auth line**

  * Clear distinction between “offline and cannot log in” vs “online but unauthorized/expired token”.
* Foreground handling:

  * On app resume:

    * Baseline: optional refresh for critical data.
    * Auth: optional token refresh + data refresh (guarded by backpressure and retry policies).

---

## Observability (Analytics, Perf, Crash)

**Analytics allow-list (stable names)**

* Lifecycle

  * `app_launch`
  * `config_loaded`
* Onboarding

  * `onboarding_view`
  * `onboarding_complete`
  * `onboarding_skip`
* Home

  * `home_view`
  * `home_refresh`
  * `home_error`
* Auth (v0.9+)

  * `login_view`
  * `login_attempt`
  * `login_success`
  * `login_failure`
* Error UX

  * `error_shown` (with `error_category`)

**Performance marks**

* `cold_start_ms`
* `home_ready_ms`
* `login_latency_ms` (v0.9+)

Define start/stop points in docs (e.g., process start → first frame rendered for `cold_start_ms`).

**Consent**

* Telemetry off by default until user consent is captured (if required in your jurisdiction).
* Respect OS-level privacy/analytics settings.

**Crash reporting**

* Crash facade in Core.
* Per app, bind a concrete vendor.
* Attach only:

  * Route IDs.
  * Error categories.
  * Non-sensitive breadcrumbs (e.g., “login_attempt”, “home_refresh”).

---

## Accessibility & Internationalization

* Touch targets ≥ 44x44 dp.
* Logical, predictable focus order.
* Screen transitions and critical messages announced to screen readers.
* Text scaling:

  * Validate at 1.0 / 1.3 / 1.6 system scales.
* i18n:

  * All user-visible strings are keyed (no inline literals).
  * Allow ~30–50% string expansion.
  * Layouts are RTL-safe.

---

## Theming & UI Abstraction

* **Theme adapter** (optional but recommended):

  * Exposes **semantic roles** (e.g., `primaryAction`, `secondaryAction`, `dangerAction`, `surfaceBackground`, `textMuted`) instead of raw color constants.
  * Features only reference roles; actual tokens are provided by the app.

* **Fallback theme**

  * If no theme adapter is wired, a neutral default theme is used.

* No fixed dependency on any particular component library; apps can adopt Material 2/3 or custom kits by plugging into the theme adapter.

---

## Error Taxonomy & Display Policy

**Categories (fixed)**

* Network & server:

  * `network_offline`
  * `timeout`
  * `server_5xx`
  * `bad_request`
* Auth-related (auth line, v0.9+):

  * `unauthorized`
  * `forbidden`
  * `invalid_credentials`
  * `token_expired`
* Resource:

  * `not_found`
* Data & unknown:

  * `parse_error`
  * `unknown`

**For each category define**

* **User copy key** (i18n-driven; no hardcoded strings in code).
* **Retry strategy**

  * `auto` / `manual` / `none`.
  * Max attempts and backoff rules.
* **UI surface**

  * Inline error card.
  * Non-blocking banner.
  * Snackbar/toast.
  * Avoid modal dialogs for most cases.
* **Telemetry tag**

  * Category name and counters per session.

---

## Testing Strategy

**Unit tests**

* Baseline:

  * Config precedence & caching behavior.
  * Error mapping to user policies.
  * Retry/backoff and cancellation behavior.
* Auth line (v0.9+):

  * Session lifecycle (login, logout, token refresh, expiry).
  * Guard logic for protected routes.

**Widget tests**

* Onboarding:

  * First-run behavior.
  * Skip/complete flows.
  * Routing decision to Home (baseline) or Login/Home (auth line).
* Home:

  * `loading/empty/error/ready` UI states.
  * Retry idempotence.
* Auth (v0.9+):

  * Form validation and error display.
  * Login success/failure paths.

**Integration tests**

* Baseline (v0.1 → v0.8):

  * Fresh install → Onboarding → Home.
  * Returning user with onboarding complete → Home.
* Auth line (v0.9+):

  * Fresh install → Onboarding → Login → Home.
  * Returning user with valid session → Home.
  * Returning user with expired session → (optional silent refresh) → Login.

**Golden tests (optional, theme-agnostic)**

* Onboarding, Home (and Login in v0.9+), in:

  * Light/dark theme.
  * Text scales 1.0 / 1.3 / 1.6.

**Non-functional**

* A11y checks.
* Basic bundle size & cold-start budgets.
* Analytics schema validation (no non-allow-listed events).

---

## CI/CD Gates

**Every PR**

* Static analysis & formatting.
* Unit + widget tests (and goldens if configured).
* Analytics schema check:

  * Only allow-listed events permitted.
* Secrets scan and denylist patterns.

**Nightly (optional)**

* Device-farm smoke tests:

  * Cold start metrics.
  * Baseline flows (Onboarding → Home).
  * Auth flows for v0.9+ (Onboarding → Login → Home).

**Release jobs (per app using the starter)**

* Signed builds per flavor (dev/stage/prod).
* Changelog enforcement.
* Performance and size budgets verified against thresholds.

---

## Release Plan (v0.1 → v0.9)

> All versions share the same architecture. The line splits at **v0.8/v0.9**:
>
> * **v0.8**: hardened baseline with **no auth** — recommended starting point for apps that never need auth.
> * **v0.9**: introduces auth on top — recommended starting point for apps that require auth.

### v0.1 — Skeleton & Contracts

* **Theme:** Laying the foundation.
* **Deliverables:**

  * Project directory layout and build system.
  * Empty feature shells (Onboarding, Home).
  * Core interfaces (signatures only) for `ConfigService`, `NavService`, `ErrorHandler`.
  * Initial error taxonomy outline.
  * ADR template and first ADRs (routing, DI, project structure).
* **Quality Gates:**

  * Linting and formatting pipelines pass.
  * Unit test harness runs.
  * App builds and shows a placeholder screen.

### v0.2 — Navigation & Routing Foundation

* **Theme:** How the user moves through the app.
* **Deliverables:**

  * Route registry assembled from feature manifests.
  * Guard system with deterministic order and redirect policies.
  * Deep link rules (e.g., `/home`, `/onboarding`).
  * Launch state machine stub using fake data stores.
* **Quality Gates:**

  * Navigation tests for guard paths & deep links (≥ ~70% coverage).
  * All guarded routes behave correctly with static flags.

### v0.3 — Configuration & Feature Flags

* **Theme:** Controlling behavior without redeploying.
* **Deliverables:**

  * `ConfigService` with precedence (defaults → cached → remote).
  * Cold start uses cached config; remote refresh is async.
  * Flags for:

    * `onboarding.enabled`
    * Home variants (`home.layout` or similar).
* **Quality Gates:**

  * App is usable offline with cached config.
  * Startup uses ≤ 2 remote calls.
  * Tests prove config precedence ordering.

### v0.4 — Error Policy & Resilience

* **Theme:** Predictable failure behavior.
* **Deliverables:**

  * Error→policy mapping (retry, show, redirect, ignore).
  * Capped exponential backoff with jitter.
  * Cancellation tokens wired from UI to network.
  * Spec for how errors are shown in UI (banner vs inline vs toast).
* **Quality Gates:**

  * Chaos tests (network failures, slow responses) pass.
  * Cancellation verified when navigating away.

### v0.5 — Observability & Telemetry

* **Theme:** Seeing what the app is doing.
* **Deliverables:**

  * Analytics facade with event allow-list and consent handling.
  * Performance marks for cold start and Home readiness.
  * Crash reporting facade.
  * CI check that only allow-listed events are used.
* **Quality Gates:**

  * Observed events match defined schema.
  * PII scans on events pass.

### v0.6 — Offline-First & Data Resilience

* **Theme:** Still useful with a bad connection.
* **Deliverables:**

  * `NetworkStatus` abstraction and minimal offline UI.
  * Last-known-good strategy for Home.
  * Foreground refresh policy (e.g., refresh on app resume with backpressure rules).
* **Quality Gates:**

  * Key paths (esp. Home) are functional in airplane mode (within reason).
  * Retry ceilings honored; no infinite retries.

### v0.7 — Accessibility, i18n & Theming

* **Theme:** Usable for real humans in multiple locales.
* **Deliverables:**

  * A11y checklist and automated checks in CI.
  * i18n framework with string keys and at least one extra locale.
  * RTL audit and fixes.
  * Theme adapter contract and neutral default implementation.
* **Quality Gates:**

  * A11y CI checks pass.
  * Pseudo-locale build works without catastrophic layout issues.
  * Light/dark theme snapshots validated.

### v0.8 — Baseline Hardened (No-Auth Line)

* **Theme:** Production-ready baseline without auth.
* **Deliverables:**

  * All non-auth features and infra hardened:

    * Onboarding.
    * Home.
    * Config, navigation, error handling, offline, observability, theming, a11y.
  * Sample “Vertical Feature” demonstrating best practices.
  * Threat model for non-auth flows (config, analytics, storage).
* **Quality Gates:**

  * All E2E baseline flows green:

    * First install → Onboarding → Home.
    * Return launches → Home.
  * Coverage ≥ ~80% on critical code paths.
  * Cold-start and bundle-size budgets met.
* **Usage note:**

  * This is the **tag to fork** for apps that **do not need authentication**.
  * Future auth work does not have to be pulled in.

### v0.9 — Auth Extension Line (Auth Apps Only)

* **Theme:** Add authentication on top of the v0.8 baseline.
* **Deliverables:**

  * `core/auth/` contracts and `features/auth/` module.
  * Email/password login UI and logic.
  * `AuthService` and `SessionStore` contracts wired in `app/`.
  * `requiresAuth` and `requiresNoAuth` guards integrated into routing.
  * Startup flow extended to handle session restoration and Login.
* **Quality Gates:**

  * E2E auth flows green:

    * First install → Onboarding → Login → Home.
    * Return with valid session → Home.
    * Optional: expired session → Login flow.
  * Tokens stored only in secure storage.
  * No tokens or credentials appear in logs or analytics.
* **Usage note:**

  * This is the **tag to fork** for apps that **require authentication**.
  * There is no config switch to disable auth in v0.9+; if you don’t want auth, start at v0.8 instead.

---

## Operational Playbooks

### Add a Feature

1. Create `features/<name>/` with:

   * `ui/`, `logic/`, `domain/`, `data/`.
2. Define the feature Manifest:

   * Routes, guard requirements, dependencies, analytics events.
3. If new infra is needed:

   * Add Core interfaces (in `core/contracts/`), not concrete classes.
4. Bind implementations in `app/di/`.
5. Add unit, widget, and integration tests as relevant.
6. Add events to analytics allow-list.

### Touch Core Safely

* Core should remain small: **interfaces, primitives, policies**.
* Any breaking change to Core:

  * Requires an ADR.
  * Requires migration notes and a minor version bump of the starter.

### Breaking Changes & Versioning

* Use semantic versioning for the starter:

  * Breaking template changes → **minor** bump (until 1.0).
* Maintain `CHANGELOG.md`:

  * List changes.
  * Note which line (baseline vs auth) is impacted.
  * Provide migration notes.

---

## MVP Acceptance Criteria

### Baseline (v0.8)

* On first launch with onboarding enabled:

  * Onboarding appears.
  * **Skip/Complete** sets `onboardingSeen` and navigates to Home.
* On subsequent launches:

  * Home is shown directly (if onboarding is disabled or already seen).
* Home:

  * Renders **loading / empty / error / ready** states correctly.
  * Retry is idempotent and non-blocking.
* Architecture:

  * Features depend only on Core contracts.
  * No cross-feature imports.
* Infra:

  * Config precedence works.
  * Error handling, offline behavior, observability, theming, a11y all wired according to spec.

### Auth Line (v0.9)

* Login:

  * Validates input before calling backend.
  * Handles server failures and `invalid_credentials` cleanly.
  * Persists session securely.
* Startup:

  * With valid session → Home (bypasses Login).
  * Without session → Login (or Onboarding first if not seen).
* Guards:

  * `requiresAuth` correctly blocks protected routes for unauthenticated users.
  * `requiresNoAuth` prevents logged-in users from going back to Login.
* Observability:

  * Auth events emitted as per allow-list (`login_attempt`, `login_success`, etc.).
  * No credentials in logs or telemetry.

---

## Risks & Mitigations

* **Starter bloat**

  * Keep Core contract-only; move heavy code to `app/` and features.
* **Vendor lock-in**

  * Hide vendors (HTTP/router/analytics/crash) behind Core interfaces.
* **Hidden coupling between baseline and auth**

  * Make sure v0.8 contains **no auth code**; introduce auth only in v0.9.
  * Be explicit in docs and changelog about what each tag includes.
* **Performance drift**

  * Maintain CI checks for cold start, bundle size, and network calls count.
* **Security drift (auth line)**

  * Regular secrets scans.
  * Logging redaction tests.
  * ADRs for any changes to auth or storage policies.
* **Consumers picking the wrong tag**

  * Document clearly:

    * “If you don’t need auth, fork v0.8.”
    * “If you need auth, fork v0.9+.”

---

## Glossary

* **Core**
  Cross-cutting interfaces, primitives, and policies; no feature-specific logic.

* **Feature**
  Vertical slice owning routes, state, use cases, and (optionally) data access.

* **Manifest**
  A feature’s declaration of routes, guards, dependencies, and analytics events.

* **Guard**
  Route-time policy controlling access (onboarding/auth constraints).

* **Baseline line**
  Versions **v0.1 → v0.8** of the template, which have **no auth**.

* **Auth line**
  Versions **v0.9+** of the template, which include the auth module.

* **Allow-list**
  Set of analytics events that are permitted to be emitted.

* **Single-flight**
  Ensuring only one in-flight token refresh at any given time.

* **Tag**
  Git tag (e.g., `v0.8.0`, `v0.9.0`) that consumers fork from to start their app.

---

### Notes for Consumers

* If your app **doesn’t need authentication**, fork **v0.8** and ignore later tags.
* If your app **needs authentication**, fork **v0.9+** and wire your backend into `AuthService` and `SessionStore`.
* Don’t try to “fake” a mode by toggling flags; use the right **tag** so you’re not carrying unused complexity.

