/// Result of a guard evaluation
sealed class GuardResult {
  const GuardResult();
}

/// Guard allows navigation to proceed
class GuardAllow extends GuardResult {
  const GuardAllow();
}

/// Guard blocks navigation and redirects to another route
class GuardRedirect extends GuardResult {
  final String targetRouteId;
  final Map<String, dynamic>? params;

  const GuardRedirect(this.targetRouteId, {this.params});
}

/// Navigation guard contract
/// Guards are evaluated in a specific order defined by the router
abstract interface class NavigationGuard {
  /// Evaluate if navigation to the target route should be allowed
  ///
  /// [targetRouteId] - The route being navigated to
  /// [currentRouteId] - The current route (may be null on initial navigation)
  Future<GuardResult> evaluate(String targetRouteId, String? currentRouteId);

  /// Priority of this guard (lower numbers execute first)
  /// Standard priorities:
  /// - 0: Onboarding guard
  /// - 10: Auth guard
  /// - 20: No-auth guard
  int get priority;

  String get name;
}
