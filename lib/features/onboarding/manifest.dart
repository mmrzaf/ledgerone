class OnboardingManifest {
  static const String routePath = '/onboarding';
  static const String routeId = 'onboarding';

  static const List<String> guards = [];

  static const List<String> events = [
    'onboarding_view',
    'onboarding_complete',
    'onboarding_skip',
  ];

  static bool matchesDeepLink(Uri uri) {
    return uri.path == routePath;
  }
}
