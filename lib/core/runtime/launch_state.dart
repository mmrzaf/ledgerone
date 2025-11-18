/// Represents the state of the app at launch
class LaunchState {
  final bool onboardingSeen;
  final bool isAuthenticated;
  final String? initialDeepLink;

  const LaunchState({
    required this.onboardingSeen,
    required this.isAuthenticated,
    this.initialDeepLink,
  });

  String determineInitialRoute() {
    if (!onboardingSeen) {
      return 'onboarding';
    }

    if (isAuthenticated) {
      return 'home';
    }

    return 'login';
  }

  @override
  String toString() => 'LaunchState(onboarded: $onboardingSeen, '
      'authenticated: $isAuthenticated, deepLink: $initialDeepLink)';
}

abstract interface class LaunchStateResolver {
  Future<LaunchState> resolve();
}
