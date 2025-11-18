abstract interface class NavigationService {
  /// Navigate to a route by ID
  void goToRoute(String routeId, {Map<String, dynamic>? params});

  /// Navigate to a route and replace the current route
  void replaceRoute(String routeId, {Map<String, dynamic>? params});

  /// Go back to the previous route
  void goBack();

  /// Check if we can go back
  bool canGoBack();

  /// Get the current route ID
  String? get currentRouteId;

  /// Clear the navigation stack and go to a route
  void clearAndGoTo(String routeId, {Map<String, dynamic>? params});
}
