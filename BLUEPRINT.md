# Flutter Starter Template — Project Blueprint (v0.1 → v0.9)

> **Purpose**
> A reusable, UI-agnostic Flutter project skeleton you can fork for new apps. It prioritizes **structure, stability, scalability, security, and efficiency**, so you can focus on features—not plumbing.
> **Auth** is **email + password only** (no signup, no forgot, no OAuth).
> **Screens**: **Onboarding → Login → Home**.

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

* Three core screens: **Onboarding**, **Login (email+password)**, **Home**.
* No signup/forgot/OAuth.
* Template is **UI/theme agnostic**; swap any design system later.

**Principles**

* **Stable**: minimal global state; explicit contracts; predictable boot.
* **Scalable**: vertical feature modules; interfaces in Core; implementations swappable.
* **Secure**: least privilege; secure storage; redacted logs; safe defaults.
* **Efficient**: fast cold start; lazy work; cancellable I/O; capped retries.
* **Clear**: every decision documented; tests cover contracts and flows.

---

## Targets & Assumptions

* Flutter stable, Dart 3+.
* Platforms: Android, iOS, Web (web auth behind a feature flag if your backend supports it).
* No vendor lock-in: HTTP client, DI, router, analytics, crash reporter are **behind interfaces**.

---

## Project Structure

```
app/            # Composition root (DI wiring, route assembly, app lifecycle)
core/           # Interfaces, primitives, cross-cutting concerns (no app logic)
  contracts/    # Service interfaces (AuthService, ConfigService, etc.)
  errors/       # Error taxonomy, result types, error→policy mapping
  policy/       # Security, logging, telemetry allow-list
  runtime/      # Clock, UUID, cancellation token, network status abstractions
  config/       # Flag/env access abstraction
  storage/      # SessionStore, UserPrefs interfaces
  network/      # HttpClient abstraction, interceptor contracts
features/
  onboarding/   # ui/, logic/, domain/ (use cases), data/ (mappers/repos if any)
  auth/         # ui/, logic/, domain/, data/ (no signup/forgot)
  home/         # ui/, logic/, (optional) data/
shared/         # Optional: a11y helpers, simple UI primitives; no app logic
assets/         # i18n placeholders, images (optional)
test/           # unit/, widget/, integration/ (mirrors src)
docs/           # ADRs, playbooks, release notes, security notes
tool/           # CI configs, scripts (no secrets)
```

**Rules**

* Features **do not** import each other. They depend only on **Core contracts**.
* **App** composes DI bindings and route table.
* **Core** contains **interfaces and primitives only** (no business logic).

---

## Layering & Dependency Rules

* **UI ↔ Feature Logic (state) ↔ Use Cases ↔ Repositories ↔ Data Sources**
* **Contracts live in Core**. Concrete implementations live outside Core (e.g., in `app/` or `features/*/data/`).
* DI binds **interface → implementation** once at startup. Features request interfaces only.
* Cross-cutting policies (security/logging/telemetry/error) live in Core and are **consumed** uniformly.

---

## Feature Modules

Each feature supplies a **Manifest** and follows the same contract pattern.

### Manifest (per feature)

* **Routes it owns**: route IDs (strings), path patterns, deep link targets.
* **Guards required**: `requiresOnboarding`, `requiresAuth`, `requiresNoAuth`.
* **Public events**: analytics event names/properties used by the feature.
* **Dependencies requested**: Core interfaces only.
* **State surface**: inputs, outputs, events (UI-agnostic description).

### Onboarding (requirements)

* Purpose: mark first-run guidance complete or skipped.
* State: current step index; boolean `onboardingSeen`.
* Outputs:

  * `onboardingSeen = true` on **Complete** or **Skip**.
* Routing:

  * On complete/skip → if session exists: **Home**; else: **Login**.
* Constraints:

  * No permission prompts here; request later in context.
* Analytics:

  * `onboarding_view`, `onboarding_complete`, `onboarding_skip`.

### Login (email/password only)

* Inputs: `identifier`, `password`.
* Validation: local, minimal; button disabled until valid.
* Operations:

  * `login(identifier, password)` → persists session on success.
  * `logout()` available globally.
* Errors:

  * Neutral messages (don’t reveal whether email exists).
* Routing:

  * On success → **Home**.
  * If deep link targets guarded route, re-run guards post-login.
* Analytics:

  * `login_view`, `login_attempt`, `login_success`, `login_failure`.

### Home

* States: **loading / ready / empty / error** (error is inline, retryable).
* Must: support background refresh on foreground; pull-to-refresh optional.
* Analytics:

  * `home_view`, `home_refresh`, `home_error`.

---

## Navigation & Guards

* **Route IDs**: string constants owned by features; no assumptions about widget style.
* **Guard types** (owned by App):

  * **requiresOnboarding**: block until `onboardingSeen = true`.
  * **requiresAuth**: redirect unauthenticated users to Login.
  * **requiresNoAuth**: redirect authenticated users away from Login to Home.
* **Guard behavior**:

  * Deterministic order: `requiresOnboarding` → `requiresAuth` → `requiresNoAuth`.
  * Deep links that hit guarded routes: guard decides redirect; original intent may be retried post-auth.
* **Initial route decision** (App launch state machine):

  1. Load flags/env (cached first).
  2. Read `onboardingSeen`.
  3. Read current session (and try silent refresh).
  4. Route:

     * First install: **Onboarding**.
     * No session: **Login**.
     * Valid session: **Home**.

---

## Configuration & Flags

* **Sources & Precedence**

  1. Built-in defaults (bundled).
  2. Remote flags (optional).
  3. Developer overrides (dev-only).

* **Caching**: cache last-known flags; define TTL; cold start uses cache; refresh async.

* **Access**: single **Config Service**; features never read env directly.

* **Representative keys** (examples; adapt as needed):

  * `auth.enabled` (bool)
  * `onboarding.enabled` (bool)
  * `telemetry.enabled` (bool)
  * `theme.tokens.enabled` (bool)
  * `home.sections` (list)

* **Build-time keys** (compile-time):

  * `APP_ENV` (dev/stage/prod)
  * `API_BASE_URL` (string)

---

## Security & Privacy

* **Credentials**: tokens in secure platform storage; never in plain prefs.
* **Networking**: HTTPS only; optional cert pinning policy; auth header injected via interceptor.
* **Token refresh**: single-flight locking; clock-skew tolerance; backoff with cap.
* **Logging**: redact tokens and PII; debug logs off in release by default.
* **Clipboard/Screenshots**: disabled for password by default; configurable via flag.
* **Crash reporting**: behind flag; sanitize stack/context.
* **Rate limiting**: client-side debounce/throttle for login attempts.
* **Data minimization**: analytics contains no PII; user ID hashed.

---

## Performance Requirements

* **Cold start**: ≤ **1.5s** on mid-range Android (debug budgets separate from release).
* **Startup network**: ≤ **2 calls** (flags + optional session refresh).
* **Home first content**: ≤ **500ms** after auth settled.
* **I/O**: all network calls cancellable; retries use capped exponential backoff with jitter.
* **Memory**: avoid long-lived singletons with heavy fields; lazy-init where possible.

---

## Offline & Resilience

* **NetworkStatus** abstraction; offline banner policy.
* **Cache**: allow last-known flags and Home content (if applicable) to render.
* **Retry**: backoff policy defined per error category; cancel on navigation.
* **Foregrounding**: on app resume, refresh session and critical data (guarded by backpressure).

---

## Observability (Analytics, Perf, Crash)

* **Allow-list events** (stable names):

  * `app_launch`, `config_loaded`,
  * `onboarding_view`, `onboarding_complete`, `onboarding_skip`,
  * `login_view`, `login_attempt`, `login_success`, `login_failure`,
  * `home_view`, `home_refresh`, `home_error`,
  * `error_shown` (with category).
* **Performance marks**:

  * `cold_start_ms`, `login_latency_ms`, `home_ready_ms` (define start/stop points in docs).
* **Consent**:

  * Telemetry disabled until consent; respect OS-level privacy settings.
* **Crash**:

  * Facade interface only; choose vendor per-app; attach breadcrumbs (route changes, error categories only).

---

## Accessibility & Internationalization

* **A11y**: tap targets ≥ 44x44; correct focus order; semantic announcements for screen changes.
* **Contrast**: enforce minimum text contrast (configurable threshold).
* **Text scaling**: verify at 1.0 / 1.3 / 1.6.
* **i18n**: all user-facing strings are keyed; allow ~30% expansion for languages like DE/FR; RTL-safe layouts.

---

## Theming & UI Abstraction

* **Theme adapter** (optional): features request **semantic roles** (e.g., “primary action”, “subtle text”) not concrete colors.
* If no adapter is provided, fallback to neutral defaults (kept simple).
* No default component library is imposed. Choose per project.

---

## Error Taxonomy & Display Policy

**Categories (fixed)**

* `network_offline`, `timeout`, `server_5xx`, `bad_request`,
* `unauthorized`, `forbidden`, `not_found`,
* `invalid_credentials`, `token_expired`,
* `parse_error`, `unknown`.

**For each category define**

* **User copy key** (i18n-driven).
* **Retry strategy**: auto / manual / none; max attempts; backoff ceiling.
* **UI surface**: inline card, non-blocking banner, or toast (avoid modals).
* **Telemetry tag**: category name + occurrence counter.

---

## Testing Strategy

* **Unit**

  * Auth lifecycle (success, invalid creds, refresh, expiry).
  * Config precedence & caching.
  * Retry/backoff & cancellation tokens.
* **Widget**

  * Onboarding flow (skip/complete → routing; persistence).
  * Login form (validation, error states, disabled/enabled CTA).
  * Home states (loading/empty/error/ready; retry idempotence).
* **Integration**

  * Fresh install → Onboarding complete → Login → Home.
  * Returning user with valid session → Home.
  * Returning user with expired token → silent refresh fail → Login.
* **Golden (theme-agnostic)**

  * Onboarding, Login, Home under light/dark and text scales 1.0/1.3/1.6.
* **Non-functional**

  * Accessibility thresholds.
  * Basic size and cold-start budgets.
  * Analytics schema validation (allow-list only).

---

## CI/CD Gates

* **Every PR**

  * Static analysis & formatting.
  * Unit + widget + (optionally) golden tests.
  * Analytics schema check (no rogue events).
  * Secrets scan; denylist patterns.
* **Nightly (optional)**

  * Device-farm smoke for cold start & flows.
* **Release jobs (when attached to an app)**

  * Signed builds per flavor (dev/stage/prod).
  * Changelog enforcement.

---

Of course. Moving authentication later is an excellent strategic decision. It allows the team to build and validate the core application infrastructure (navigation, error handling, configuration) without the complexity of a stateful auth system.

Here is the improved release plan, which defers authentication to **v0.7** and re-sequences the work for a more logical, de-risked flow.

---

## Release Plan (v0.1 → v0.9)

*Each release builds a stable, tested foundation for the next.*

### v0.1 — Skeleton & Contracts
*   **Theme:** Laying the foundation.
*   **Deliverables:**
    *   Project directory layout and build system.
    *   Empty feature shells (UI components and state management placeholders).
    *   Core interfaces (names and signatures only for `ConfigService`, `NavService`, `ErrorHandler`).
    *   Error taxonomy (categorization of errors: `Recoverable`, `Fatal`, `Offline`).
    *   ADR (Architecture Decision Record) template and initial ADRs.
*   **Quality Gates:**
    *   Linting and formatting pipelines pass.
    *   Initial unit test harness executes successfully.
    *   Build produces a runnable, empty application.
*   **Upgrade Notes:** None.

### v0.2 — Navigation & Routing Foundation
*   **Theme:** Defining how the user moves through the app.
*   **Deliverables:**
    *   Route registry dynamically assembled from feature manifests.
    *   Guard system with order-of-execution and redirect policies.
    *   Deep link routing rules (e.g., `/feature/:id`).
    *   Launch state machine (using fake/static data stores).
*   **Quality Gates:**
    *   Navigation unit tests for guard paths & deep links achieve ≥70% coverage.
    *   All guarded routes correctly block or allow access based on static flags.
*   **Upgrade Notes:** Guard APIs are now stable.

### v0.3 — Configuration & Feature Flags
*   **Theme:** Controlling app behavior without deployments.
*   **Deliverables:**
    *   `ConfigService` with precedence (defaults → cached → remote) and in-memory caching.
    *   Application cold-starts using cache, with async refresh in the background.
    *   Feature flag gating for critical flows (e.g., onboarding, home screen variants).
*   **Quality Gates:**
    *   App boots and is usable offline with cached config.
    *   Startup sequence makes ≤2 remote calls.
    *   Comprehensive tests for config precedence (cache wins over default, remote wins over cache).
*   **Upgrade Notes:** Flag keys are frozen and should be treated as a public API.

### v0.4 — Error Policy & Resilience
*   **Theme:** The app behaves predictably when things go wrong.
*   **Deliverables:**
    *   Error-to-user-facing-policy mapping (e.g., retry, show message, redirect).
    *   Capped exponential backoff with jitter for all network operations.
    *   Cancellation tokens wired end-to-end (abort on navigation, component unmount).
    *   Specification for how and where errors are surfaced in the UI.
*   **Quality Gates:**
    *   Chaos tests (simulating network failures, slow responses) pass.
    *   Cancellation is verified to work during navigation.
*   **Upgrade Notes:** Error categories are frozen.

### v0.5 — Observability & Telemetry
*   **Theme:** Understanding how the app performs in the wild.
*   **Deliverables:**
    *   Analytics facade with event allow-listing and consent management.
    *   Performance marks/metrics for app startup and key user flows.
    *   Crash reporting facade.
    *   Event schema validation in CI.
*   **Quality Gates:**
    *   Only allow-listed events are emitted.
    *   Performance marks are emitted for critical startup path.
    *   Privacy lint (checking for PII in events) passes.
*   **Upgrade Notes:** Event names are a public API. Changing them breaks dashboards.

### v0.6 — Offline-First & Data Resilience
*   **Theme:** The app remains functional without a perfect connection.
*   **Deliverables:**
    *   `NetworkStatus` abstraction and UI indicator (e.g., offline banner).
    *   "Last-known-good" data strategy for the Home screen.
    *   Foreground data refresh policy (e.g., refresh on app focus).
    *   Simple read-through caching for non-user data.
*   **Quality Gates:**
    *   All critical paths pass in flight-mode (offline).
    *   Backoff and retry ceilings are respected.
*   **Upgrade Notes:** None.

### v0.7 — Authentication Lifecycle
*   **Theme:** Securely managing user identity and session.
*   **Deliverables:**
    *   Email/password login flow.
    *   Secure session storage (e.g., encrypted storage, not plain text).
    *   Silent token refresh mechanism with single-flight protection.
    *   Auth guards integrated with navigation, enforcing redirects to login.
*   **Quality Gates:**
    *   End-to-end integration tests for flows: first-run, expired token → login, successful login → redirect to deep link.
    *   Session is not lost on app restart.
*   **Upgrade Notes:** Session data model is now locked.

### v0.8 — Accessibility, i18n & Theming
*   **Theme:** Making the app usable for everyone.
*   **Deliverables:**
    *   A11y checklist and automated CI rules for WCAG compliance.
    *   Internationalization (i18n) framework with string keys; RTL (Right-to-Left) layout audit.
    *   Theme adapter contract with semantic roles (e.g., `colorPrimary`, `textHeadline`) and neutral fallback.
*   **Quality Gates:**
    *   A11y CI checks pass.
    *   Pseudo-locale build works without layout breaks; snapshots for dark/light themes are verified.
*   **Upgrade Notes:** Theme semantic role names are locked.

### v0.9 — Hardening & Release Candidate
*   **Theme:** Ensuring production readiness.
*   **Deliverables:**
    *   Threat model mini-review focused on new auth and data flows.
    *   Logging redaction verified (no tokens, PII in logs).
    *   Secrets scan in codebase.
    *   Performance budget checks (bundle size, cold-start time).
    *   Example "sample feature" proving the complete extension path for app developers.
    *   Migration guide from v0.9 to a hypothetical app-specific 1.0.
*   **Quality Gates:**
    *   All E2E critical user flows are green.
    *   Overall code coverage ≥80%.
    *   Bundle size and cold-start time budgets are met.
    *   CHANGELOG is comprehensive and ready for 1.0.
*   **Upgrade Notes:** This is the stable base for forking to app-specific **1.0**.

---

### How to Ship 1.0 for a New App

1.  **Fork** the `v0.9` tag.
2.  **Implement** your brand-specific theme adapter.
3.  **Bind** real networking and auth backend services.
4.  **Build** your first full-stack domain feature using the proven path from the "sample feature".
5.  **Run** the v0.9 hardening checklist again with your app's specific requirements.
6.  **Tag** your stable, production-ready `1.0.0`.

---

## Operational Playbooks

### Add a Feature (recipe)

1. Create `features/your_feature/` with `ui/`, `logic/`, `domain/`, `data/`.
2. Define the **Manifest** (routes, guards, dependencies, events).
3. If new data is needed, define **repository interfaces** in Core.
4. Bind implementations in App DI (not in Core).
5. Add tests (unit/widget/integration as relevant).
6. Document any new analytics events (must be on the allow-list).

### Touch Core Safely

* Open an ADR. Keep Core small (interfaces, primitives, policies).
* Any breaking change to Core contracts requires a migration note and minor version bump.

### Breaking Changes & Versioning

* Semantic versioning: breaking template changes → **minor** bump until 1.0.
* Maintain a `CHANGELOG.md` with migration snippets.

---

## MVP Acceptance Criteria

* On first launch, Onboarding appears; **Skip**/**Complete** sets `onboardingSeen` and routes correctly.
* Login accepts **email/password**, prevents invalid submissions, handles server errors neutrally, persists session, and routes to Home.
* Home renders **loading / empty / error / ready**; retry is idempotent and non-blocking.
* Session persists across restarts; expired sessions attempt silent refresh; on failure, route to Login.
* Features depend only on Core interfaces; no cross-feature imports.
* Swapping theme or component library requires **zero** changes to business logic.

---

## Risks & Mitigations

* **Starter bloat** → Keep Core interface-only; push implementations to app layer.
* **Vendor lock-in** → All vendors behind interfaces (HTTP, router, analytics, crash).
* **Hidden coupling** → Enforce dependency rules via code review + CI checks.
* **Perf drift** → CI budget checks for cold start and bundle size.
* **Security drift** → Secrets scan; logging redaction tests; ADRs for policy changes.

---

## Glossary

* **Core**: Cross-cutting interfaces, primitives, and policies (no app feature logic).
* **Feature**: Vertical slice owning routes, state, and use cases (e.g., onboarding/auth/home).
* **Manifest**: A feature’s declaration of routes, guards, dependencies, and analytics events.
* **Guard**: Route-time policy that controls access (onboarding/auth).
* **Allow-list**: The only analytics events permitted to be emitted.
* **Single-flight**: Ensure only one in-progress token refresh at a time.

---

### Notes for Consumers

* This blueprint intentionally avoids picking libraries for routing, state, HTTP, DI, analytics, or crash reporting. Choose what suits your project and bind them behind the provided contracts.
* Keep the **contracts stable**. Swap implementations, not interfaces.

