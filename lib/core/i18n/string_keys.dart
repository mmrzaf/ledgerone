/// Central registry of all localization keys
/// This ensures type-safe string references and prevents typos
class L10nKeys {
  // Common
  static const String appName = 'app.name';
  static const String ok = 'common.ok';
  static const String cancel = 'common.cancel';
  static const String retry = 'common.retry';
  static const String loading = 'common.loading';
  static const String error = 'common.error';
  static const String success = 'common.success';

  // Onboarding
  static const String onboardingTitle = 'onboarding.title';
  static const String onboardingSubtitle = 'onboarding.subtitle';
  static const String onboardingGetStarted = 'onboarding.get_started';
  static const String onboardingSkip = 'onboarding.skip';

  // Login
  static const String loginTitle = 'login.title';
  static const String loginEmail = 'login.email';
  static const String loginPassword = 'login.password';
  static const String loginSubmit = 'login.submit';
  static const String loginEmailRequired = 'login.email_required';
  static const String loginEmailInvalid = 'login.email_invalid';
  static const String loginPasswordRequired = 'login.password_required';
  static const String loginPasswordTooShort = 'login.password_too_short';

  // Home
  static const String homeTitle = 'home.title';
  static const String homeWelcome = 'home.welcome';
  static const String homeRefresh = 'home.refresh';
  static const String homeLogout = 'home.logout';
  static const String homeDemoContent = 'home.demo_content';
  static const String homeRefreshInstruction = 'home.refresh_instruction';
  static const String homeNoContent = 'home.no_content';
  static const String homeLoadingContent = 'home.loading_content';
  static const String homeOfflineWarning = 'home.offline_warning';
  static const String homeCachedData = 'home.cached_data';
  static const String homeLoadedAt = 'home.loaded_at';

  // Errors
  static const String errorNetworkOffline = 'error.network_offline';
  static const String errorTimeout = 'error.timeout';
  static const String errorServerError = 'error.server_error';
  static const String errorBadRequest = 'error.bad_request';
  static const String errorUnauthorized = 'error.unauthorized';
  static const String errorForbidden = 'error.forbidden';
  static const String errorNotFound = 'error.not_found';
  static const String errorInvalidCredentials = 'error.invalid_credentials';
  static const String errorSessionExpired = 'error.session_expired';
  static const String errorParseError = 'error.parse_error';
  static const String errorUnknown = 'error.unknown';
  static const String errorInlineTitle = 'error.inline_title';

  // Accessibility labels
  static const String a11yNavigationBack = 'a11y.navigation.back';
  static const String a11yNavigationMenu = 'a11y.navigation.menu';
  static const String a11yCloseButton = 'a11y.close_button';
  static const String a11yRefreshButton = 'a11y.refresh_button';
  static const String a11yLoadingIndicator = 'a11y.loading_indicator';
  static const String a11yErrorIcon = 'a11y.error_icon';
  static const String a11ySuccessIcon = 'a11y.success_icon';

  // Network status
  static const String networkOffline = 'network.offline';
  static const String networkOnline = 'network.online';
  static const String networkUnknown = 'network.unknown';
}
