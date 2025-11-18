class AuthManifest {
  static const String loginPath = '/login';
  static const String loginId = 'login';

  static const List<String> guards = ['requiresOnboarding', 'requiresNoAuth'];

  static const List<String> events = [
    'login_view',
    'login_attempt',
    'login_success',
    'login_failure',
  ];

  static bool matchesDeepLink(Uri uri) {
    return uri.path == loginPath;
  }
}
