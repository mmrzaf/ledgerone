# ADR 0002: Navigation Architecture

## Status

Accepted

## Context

v0.2 requires a production-ready navigation system that:
- Supports route guards with priority-based execution
- Enables deep linking (now and in future versions)
- Remains UI/framework agnostic at the contract level
- Allows route definitions to live with features (via manifests)
- Handles complex redirect scenarios (onboarding, auth, feature flags)
- Works consistently across web, mobile, and desktop platforms

### Evaluation Criteria

1. **Guard Support**: Can we implement priority-based guards?
2. **Deep Linking**: Does it support URL-based navigation?
3. **Type Safety**: Are routes type-safe and compile-time checked?
4. **Testability**: Can we test navigation logic in isolation?
5. **Community**: Is it actively maintained?
6. **Abstraction**: Can we swap implementations later?

### Options Considered

#### Option A: go_router (Recommended by Flutter team)

**Pros:**
- Official recommendation from Flutter team
- Built-in guard support via `redirect`
- Excellent deep linking support
- Type-safe route generation available
- Active maintenance and community
- Web support out of the box

**Cons:**
- Imperative API requires some boilerplate
- Guard composition requires manual orchestration
- Learning curve for redirect logic

#### Option B: auto_route

**Pros:**
- Code generation reduces boilerplate
- Type-safe routes by default
- Guard support via annotations

**Cons:**
- Build-time code generation adds complexity
- Less flexible for runtime route assembly
- Smaller community than go_router

#### Option C: Custom router with Navigator 2.0

**Pros:**
- Complete control
- Zero dependencies
- Maximum flexibility

**Cons:**
- Significant implementation effort
- Need to handle edge cases ourselves
- Maintenance burden

## Decision

We will use **go_router** as the concrete router implementation, wrapped behind our `NavigationService` contract.

### Key Implementation Details

1. **Contract-First Design**: 
   - All navigation logic depends on `NavigationService` interface
   - go_router implementation lives in `app/` layer
   - Features never import go_router directly

2. **Guard Orchestration**:
   - Guards implement `NavigationGuard` interface
   - Sorted by priority before registration
   - Evaluated sequentially in go_router's `redirect` callback
   - First redirect wins, no further evaluation

3. **Route Registry**:
   - Routes defined in feature manifests
   - Assembled dynamically in `RouterFactory`
   - Bi-directional mapping: routeId ↔ path

4. **Launch State Integration**:
   - Initial route determined before router creation
   - Guards re-evaluated on every navigation
   - Session refresh attempted in AuthGuard

### Code Structure

```dart
// Contract (core/contracts/)
abstract interface class NavigationService {
  void goToRoute(String routeId);
  // ...
}

// Implementation (app/navigation/)
class NavigationServiceImpl implements NavigationService {
  final GoRouter _router;
  // ...
}

// Composition (app/di.dart)
RouterFactory.create(
  guards: [...],
  initialRoute: launchState.determineInitialRoute(),
)
```

## Consequences

### Positive

- ✅ Strong deep linking foundation for future versions
- ✅ Easy to test guards in isolation
- ✅ Can swap router implementation if needed
- ✅ Clear separation between routing logic and UI
- ✅ Platform-agnostic navigation API

### Negative

- ⚠️ go_router redirect API requires some boilerplate
- ⚠️ Guard evaluation is async, adding latency to navigation
- ⚠️ Need to manually maintain routeId ↔ path mapping

### Risks & Mitigations

**Risk**: go_router becomes unmaintained
- **Mitigation**: All features use NavigationService contract, making migration easier

**Risk**: Guard logic becomes complex and hard to debug
- **Mitigation**: 
  - Each guard is isolated and testable
  - Guards have clear priority numbers
  - Comprehensive test coverage (>70%)

**Risk**: Navigation performance degrades with many guards
- **Mitigation**:
  - Guards short-circuit on first redirect
  - Cache guard results where appropriate (future optimization)

## Alternatives Considered But Rejected

1. **Beamer**: Less community adoption, similar complexity to go_router
2. **Fluro**: Deprecated, no longer maintained
3. **page_transition**: Too low-level, doesn't solve guard problem

## References

- [go_router documentation](https://pub.dev/packages/go_router)
- [Flutter Navigator 2.0 docs](https://docs.flutter.dev/development/ui/navigation)
- Blueprint section: Navigation & Guards

## Revision History

- 2024-11-18: Initial decision for v0.2
