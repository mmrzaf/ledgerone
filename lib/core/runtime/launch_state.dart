/// Represents the state of the app at launch
class LaunchState {
  final bool onboardingSeen;
  final String? initialDeepLink;

  const LaunchState({required this.onboardingSeen, this.initialDeepLink});

  String determineInitialRoute() {
    return onboardingSeen ? 'home' : 'onboarding';
  }

  @override
  String toString() =>
      'LaunchState(onboarded: $onboardingSeen, '
      'deepLink: $initialDeepLink)';
}

abstract interface class LaunchStateResolver {
  Future<LaunchState> resolve();
}
